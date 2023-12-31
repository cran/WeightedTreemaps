#' sunburstTreemap
#'
#' Create sunburst treemaps where variables are encoded by size of circular sectors.
#'
#' This function returns a treemap object instead of a plot. In order 
#' to actually draw the treemap, use \code{\link{drawTreemap}}.
#'
#'
#' @param data (data.frame) A data.frame with one column for each hierarchical level
#' @param levels (character) Character vector indicating the column names to 
#'   be used. The order of names must correspond to the hierarchical levels, 
#'   going from broad to fine 
#' @param fun (function) Function to be used to aggregate cell sizes of parental cells
#' @param sort (logical) Should the columns of the data.frame be sorted before?
#' @param filter (logical) Filter the supplied data frame to remove very small
#'   sectors that may not be visible. The default is to not remove any sectors.
#' @param cell_size (character) The name of the column used to control sector size. 
#'   Can be one of \code{levels} or any other column with numerical data. NA or
#'   values equal or less than zero are not allowed.
#'   The values in this column are aggregated by the function specified by \code{fun}.
#'   If \code{sector_size = NULL}, sector size is simply computed by the number of members
#'   for the respective sector (corresponding to rows in the data.frame).
#' @param custom_color (character) An optional column that can be specified to
#'   control cell color. Cell colors are determined when drawing the treemap
#'   using \code{\link{drawTreemap}}, but the default is to use one of 
#'   \code{levels} or \code{cell size}. Any other data source that shall be used
#'   instead has to be included in the treemap generation and explicitly 
#'   specified here. The default value is \code{NULL}.
#' @param diameter_inner (numeric) The minimum inner diameter of the drawn map. 
#'   Defaults to 0.3,
#' @param diameter_outer (numeric) The maximum outer diameter of the drawn map. 
#'   Defaults to 0.8
#' @param verbose (logical) If verbose is TRUE (default is FALSE), basic information
#'   such as a success message is printed to the console.
#' 
#' @return `sunburstTreemap` returns an object of the formal class `sunburstResult`.
#'   It is essentially a list of objects related to the graphical
#'   representation of the treemap (polygons, labels, cell data) as well as data from the call
#'   of the function. It contains the following slots:
#'     \item{cells}{`list` of polygons for drawing a treemap}
#'     \item{data}{`data.frame`, the original data that was supplied to calling `voronoiTreemap`}
#'     \item{call}{`list` of arguments used to call `voronoiTreemap`}
#' 
#' @seealso \code{\link{drawTreemap}} for drawing the treemap.
#' 
#' @examples
#' # load example data
#' data(mtcars)
#' mtcars$car_name = gsub(" ", "\n", row.names(mtcars))
#' 
#' # generate treemap;
#' # by default cell (sector) size is encoded by number of members per group
#' tm <- sunburstTreemap(
#'   data = mtcars,
#'   levels = c("gear", "cyl"),
#'   cell_size = "hp"
#' )
#' 
#' # draw treemap with default options
#' drawTreemap(tm,
#'   title = "A sunburst treemap",
#'   legend = TRUE,
#'   border_size = 2,
#'   layout = c(1, 3),
#'   position = c(1, 1)
#' )
#' 
#' # use custom color palette
#' drawTreemap(tm,
#'   title = "Use custom palette",
#'   legend = TRUE,
#'   color_palette = rep(c("#81E06E", "#E68CFF", "#76BBF7"), c(3, 4, 5)),
#'   border_size = 2,
#'   label_level = 2,
#'   label_size = 0.7,
#'   label_color = grey(0.5),
#'   layout = c(1, 3),
#'   position = c(1, 2),
#'   add = TRUE
#' )
#' 
#' # color cells (sectors) based on cell size
#' drawTreemap(tm,
#'   title = "Coloring encoded by cell size",
#'   color_type = "cell_size",
#'   legend = TRUE,
#'   color_palette = rev(heat.colors(10)),
#'   border_size = 3,
#'   border_color = grey(0.3),
#'   label_level = 1,
#'   label_size = 2,
#'   label_color = grey(0.5),
#'   layout = c(1, 3),
#'   position = c(1, 3),
#'   add = TRUE
#' )
#' 
#' @importFrom dplyr %>%
#' @importFrom dplyr mutate_if
#' @importFrom dplyr group_by
#' @importFrom dplyr summarise
#' @importFrom dplyr pull
#' @importFrom scales rescale
#' 
#' @export sunburstTreemap
#' 
sunburstTreemap <- function(
  data, 
  levels, 
  fun = sum,
  sort = TRUE,
  filter = 0,
  cell_size = NULL,
  custom_color = NULL,
  diameter_inner = 0.3,
  diameter_outer = 0.8,
  verbose = FALSE
) {
  
  # validate input data and parameters
  data <- validate_input(
    data, levels, fun,
    sort, filter, cell_size, 
    custom_color, verbose)
  
  # CORE FUNCTION (RECURSIVE)
  sunburst_core <- function(level, df, parent = c(0, 1), output = list()) {
    
    # 1. summarise current level's category
    ncells <- df[[levels[level]]] %>% table
    
    # 2. generate the weights, these are the (aggregated) scaling factors 
    # supplied by the user or simply the n members per cell
    if (is.null(cell_size)) {
      # average cell size by number of members, if no function is given
      weights <- ncells %>% cumsum
      weights <- {weights/tail(weights, 1)}
    } else {
      # average cell size by user defined function, e.g. sum of expression values
      # the cell size is calculated as aggregated relative fraction of total
      stopifnot(is.numeric(df[[cell_size]]))
      weights <- df %>%
        dplyr::group_by(get(levels[level])) %>%
        dplyr::summarise(cumfun = fun(get(cell_size))) %>% 
        dplyr::pull(get("cumfun")) %>% cumsum
      weights <- weights/tail(weights, 1)
    }
    
    # 3. rescale the weights to lower and upper boundary of parent
    weights = scales::rescale(weights, from = c(0, 1), to = parent)
    lower_bound <- c(parent[1], weights[-length(weights)])
    upper_bound <- weights
    
    # 4. generate custom color values for each cell that can be used
    # with different palettes when drawing;
    if (!is.null(custom_color)) {
      color_value <- df %>%
        dplyr::group_by(get(levels[level])) %>%
        dplyr::summarise(fun(get(custom_color)))
      color_value <- color_value [[2]]
      color_value <- setNames(color_value, names(ncells))
    }
    
    # 5. generate sector polygons and collect in list
    sectors <- lapply(1:length(ncells), function(i) {
      
      draw_sector(
        level = level,
        lower_bound = lower_bound[[i]],
        upper_bound = upper_bound[[i]],
        diameter_inner = diameter_inner,
        diameter_sector = (diameter_outer-diameter_inner)/length(levels),
        name = names(ncells)[i],
        custom_color = ifelse(is.null(custom_color), NA, color_value[[i]])
        
      )
      
    })
    
    
    # CALL CORE FUNCTION RECURSIVELY
    if (level != length(levels)) {
      
      # iterate through all possible sub-categories,
      # these are the children of the parental polygon
      # and pass the children's polygon as new parental
      # also add current results to output list
      res <- lapply(1:length(ncells), function(i) {
        
        sunburst_core(
          level = level + 1,
          df = subset(df, get(levels[level]) %in% names(ncells)[i]),
          parent = c(lower_bound[[i]], upper_bound[[i]]),
          output = {
            output[[paste0("LEVEL", level, "_", names(ncells)[i])]] <- sectors[[i]]
            output
          }
        )
      }) %>%
      unlist(recursive = FALSE)
      return(res)
      
    } else {
      
      names(sectors) <- paste0("LEVEL", level, "_", names(ncells))
      return(c(output, sectors))
      
    }
  }
  
  # MAIN FUNCTION CALL
  # ------------------
  # iterate through all levels,
  # collect results in list, remove duplicated polygons
  # and order by hierarchical level
  tm <- sunburst_core(level = 1, df = data, parent = c(0, 1))
  tm <- tm[!duplicated(tm)]
  tm <- tm[names(tm) %>% order]
  if (verbose) {
    message("Treemap successfully created.")
  }
  
  
  # set S4 class and return result
  tm <- sunburstResult(
    cells = tm,
    data = data,
    call = list(
      levels = levels, 
      fun = fun,
      sort = sort,
      filter = filter,
      cell_size = cell_size,
      custom_color = custom_color,
      diameter_inner = diameter_inner,
      diameter_outer = diameter_outer
    )
  )

  return(tm)
  
}

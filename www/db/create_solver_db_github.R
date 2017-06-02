
setwd("/home/florian/work/Optimization/ROI/ROI_R-Forge/www/db")

source("create_solver_db_functions.R")

R <- "/home/florian/bin/R-devel/bin/R"

CRAN <- "https://cran.r-project.org/"
REPOS <- c("dirkschumacher/ROI.plugin.cbc", "datastorm-open/ROI.plugin.clp",
           "Fl0Sch/ROI.plugin.gurobi", "Fl0Sch/ROI.plugin.mosek")

## r_version, lib.loc, repos 
solver_db_github <- create_solver_db_github(R, head(.libPaths()), REPOS, CRAN)
saveRDS(solver_db_github, file = "SOLVERS_GITHUB.rds")

if (FALSE) {

    r_version <- R
    lib.loc <- head(.libPaths(), 1L)
    cran <- CRAN
    repos <- REPOS

}
## ROI plugin: ipop
## based on kernlab package
## code partially based on solver interface ipopQP from package
## fPortfolio (Thanks to Diethelm Wuertz)

## BASIC SOLVER METHOD
solve_QP <- function( x, control ) {
    ## quadprog does not support variable bounds per se, thus we add
    ## them as constraints

    ## Handle control list
    control <- match_defaults( control )

    ## solve the QP
    out <- .ipop_solve_QP( Q   = terms(objective(x))$Q,
                           L   = terms(objective(x))$L,
                           mat = constraints(x)$L,
                           dir = constraints(x)$dir,
                           rhs = constraints(x)$rhs,
                           bounds = bounds(x),
                           max = x$maximum,
                           control = control )
    ROI:::canonicalize_solution( solution = out$solution,
                                 optimum  = ifelse(is.na(out$solution), NA,
                                 objective(x)(out$solution)),
                                 status   = out$status,
                                 solver   = ROI:::get_solver_name(getPackageName()),
                                 control  = control,
                                 returnvalue = out$output )
}

solve_LP <- function( x, control ) {
    ## quadprog does not support variable bounds per se, thus we add
    ## them as constraints

    ## Handle control list
    control <- match_defaults( control )

    ## solve the QP
    out <- .ipop_solve_QP( Q   = simple_triplet_zero_matrix(length(objective(x))),
                           L   = terms(objective(x))$L,
                           mat = constraints(x)$L,
                           dir = constraints(x)$dir,
                           rhs = constraints(x)$rhs,
                           bounds = bounds(x),
                           max = x$maximum,
                           control = control )
    ROI:::canonicalize_solution( solution = out$solution,
                                 optimum  = ifelse(is.na(out$solution), NA,
                                 objective(x)(out$solution)),
                                 status   = out$status,
                                 solver   = ROI:::get_solver_name(getPackageName()),
                                 control  = control,
                                 returnvalue = out$output)
}

## SOLVER SUBMETHODS

.ipop_solve_QP <- function( Q, L, mat, dir, rhs, bounds, max, control ){

    N <- length( L )
    ## no infinte value possible, thus setting to large number
    INF <- control$inf

    # Upper and Lower Bounds:
    lower <- rep( 0, N )
    upper <- rep( INF, N )
    if( !is.null(bounds$lower$ind) ) {
        lowerIndex <- bounds$lower$ind
        lowerValues <- bounds$lower$val
        lower[lowerIndex] <- lowerValues
    }
    if( !is.null(bounds$upper$ind) ) {
        upperIndex <- bounds$upper$ind
        upperValues <- bounds$upper$val
        upper[upperIndex] <- upperValues
    }
    upper[ upper > INF ] <- INF
    lower[ lower < -INF ] <- -INF

    # Linear Constraints:
    lhs <- rep( -INF, length(dir) )
    lhs[dir %in% c(">=", ">")] <- rhs[dir %in% c(">=", ">")]
    lhs[dir == "=="] <- rhs[dir == "=="]
    rhs[dir %in% c(">=", ">")] <- INF

    if( max ){
        L <- -L
        Q <- -Q
    }

    out <- tryCatch( ipop(c = L,
                          H = as.matrix(Q),
                          A = as.matrix(mat),
                          b = lhs,
                          l = lower,
                          u = upper,
                          r = rhs - lhs,
                          sigf = control$sigf,
                          maxiter = control$maxiter,
                          margin = control$margin,
                          bound = control$bound,
                          verb = control$verb),
                    error = identity )
    out <- if( inherits(out, "error") )
        list( solution = NA,
              status = 2L,
              output = out)
    else
        list( solution = out@primal,
              status = ifelse(is.na(out@primal), 1L, 0L),
              output = out)
    out
}

## STATUS CODES
.add_status_codes <- function(){
    ## quadprog
    solver <- ROI:::get_solver_name( getPackageName() )
    ROI:::add_status_code_to_db(solver,
                                0L,
                                "converged",
                                "Solution is optimal",
                                0L
                                )
    ROI:::add_status_code_to_db(solver,
                                1L,
                                "not converged",
                                "No solution found."
                                )
    ROI:::add_status_code_to_db(solver,
                                2L,
                                "error",
                                "Solver error: No solution found."
                                )
    invisible(TRUE)
}

## UTILITIES
match_defaults <- function( control ){
    defaults <- ipop_default_control()
    if( !is.null(control) ){
        control <- lapply( names(defaults), function(x) ifelse(is.null(control[[ x ]]), defaults[[ x ]], control[[ x ]]) )
        names( control ) <- names( defaults )
    } else
    control <- defaults
    control
}

ipop_default_control <- function()
    list( sigf = 7,
          maxiter = 40,
          margin = 0.05,
          bound = 10,
          verb = 0,
          inf = 1e+12 )

nloptr_defaults <- function(x=NULL) {
    d <- nloptr.get.default.options()
    ## set variables needed to evaluate the default values
    x0 <- 0L
    num_constraints_ineq <- 1L
    num_constraints_eq <- 1L
    ## fix typo in nloptr types
    d[,'type'] <- gsub("interger", "integer", d[,'type'])
    defaults <- list()
    for (i in seq_len(nrow(d))) {
        if (d[i, 'type'] == "character") {
            defaults[[d[i, 'name']]] <- d[i, 'default']
        } else {
            defaults[[d[i, 'name']]] <- 
                tryCatch({
                    as(d[i, 'default'], d[i, 'type'])
                },
                         warning = function(w) {
                             as(eval(parse(text=d[i, 'default'])), d[i, 'type'])
                         })
        }
    }
    if ( is.null(x) ) return( defaults )
    if ( length(x) == 1L ) return( defaults[[x]] )
    return( defaults[x] )
}

nloptr_get_default <- function(x) {
    nloptr.get.default.options()[nloptr.get.default.options()[,'name'] == x, 'default']
}

## get_algorithms() returns an overview
## get_algorithms(T) returns vector with global algorithms
## get_algorithms(T) returns vector with local algorithms
## get_algorithms(NULL, T) returns vector with derivative algorithms
## get_algorithms(NULL, F) returns vector with no derivative algorithms
get_algorithms <- function(global=NULL, derivatives=NULL) {
    d <- nloptr.get.default.options()
    rownames(d) <- d[,"name"]
    a <- unlist(strsplit(d["algorithm", "possible_values"], ",\\s*"))
    algo <- data.frame(a, stringsAsFactors = FALSE)
    ## first is Global "G" vs Local "L"
    algo$global <- substr(a, 7, 7) == "G"
    ## secound Derivate "D" vs No Derivate "N"
    algo$derivatives <- substr(a, 8, 8) == "D"
    if ( is.null(global) & is.null(derivatives) )
        return( algo )
    if ( is.null(global) )
        return( algo[algo$derivatives == derivatives, 1] )
    if ( is.null(derivatives) )
        return( algo[algo$global == global, 1] )
    algo[( (algo$derivatives == derivatives) & (algo$global == global) ), 1]
}

get_algo_properties <- function() {
    get_algorithms()
}

## nloptr
## ======
##
## R interface to NLopt
##
## nloptr(x0, eval_f, eval_grad_f = NULL, lb = NULL, ub = NULL,
##        eval_g_ineq = NULL, eval_jac_g_ineq = NULL, eval_g_eq = NULL,
##        eval_jac_g_eq = NULL, opts = list(), ...)
solve_nloptr <- function( x, control ) {
    solver <- get_solver_name( getPackageName() )
    lb <- get_lb(x)
    ub <- get_ub(x)

    ## useGlobal <- #TODO
    ## use_derivatives <- 

    ## TODO: If no algorithm provided choose a algorithm based on the 
    ##       problem and the JSS paper

    if ( is.null(control$start) ) 
        stop("no start value, please provide a start value via control$start!")
    j <- na.exclude(match(c("gradient", "nl.info", "start"), names(control)))
    if ( is.null(control$xtol_rel) ) control[['xtol_rel']] <- nloptr_defaults('xtol_rel')
    if ( is.null(control$tol_constraints_ineq) ) 
        control[['tol_constraints_ineq']] <- nloptr_defaults("tol_constraints_ineq")
    if ( is.null(control$tol_constraints_eq) ) 
        control[['tol_constraints_eq']] <- nloptr_defaults("tol_constraints_eq")

    if ( is.null(control$args) ) {
        o <- nloptr(x0 = control$start, 
                    eval_f = objective(x),
                    eval_grad_f = x$objective$G, 
                    lb = lb, 
                    ub = ub,
                    eval_g_ineq = build_inequality_constraints(x, control$tol_constraints_ineq), 
                    eval_jac_g_ineq = build_jacobian_inequality_constraints(x, control$tol_constraints_ineq), 
                    eval_g_eq = build_equality_constraints(x, control$tol_constraints_eq), 
                    eval_jac_g_eq = build_jacobian_equality_constraints(x, control$tol_constraints_eq), 
                    opts = control[-j] )
    } else {
        arglist <- c(list(x0 = control$start, 
                          eval_f = objective(x),
                          eval_grad_f = x$objective$G, 
                          lb = lb, 
                          ub = ub,
                          eval_g_ineq = build_inequality_constraints(x, control$tol_constraints_ineq), 
                          eval_jac_g_ineq = build_jacobian_inequality_constraints(x, control$tol_constraints_ineq), 
                          eval_g_eq = build_equality_constraints(x, control$tol_constraints_eq), 
                          eval_jac_g_eq = build_jacobian_equality_constraints(x, control$tol_constraints_eq), 
                          opts = control[-j]),
                    control$args)
        args <- paste(paste(names(arglist), names(arglist), sep=" = "), collapse=", ")
        nloptr_call <- parse(text=sprintf("nloptr(%s)", args))        
        o <- eval(nloptr_call, envir=arglist)
    }

    canonicalize_solution(solution  = o$solution,
                          optimum   = o$objective,
                          status    = o$status,
                          solver    = solver,
                          algorithm = control$algorithm )
}

## NLOPT Algorithmen
## =================
##
## NLOPT_GN_DIRECT
## NLOPT_GN_DIRECT_L
## NLOPT_GN_DIRECT_L_RAND
## NLOPT_GN_DIRECT_NOSCAL
## NLOPT_GN_DIRECT_L_NOSCAL
## NLOPT_GN_DIRECT_L_RAND_NOSCAL
## NLOPT_GN_ORIG_DIRECT
## NLOPT_GN_ORIG_DIRECT_L
## NLOPT_GD_STOGO
## NLOPT_GD_STOGO_RAND
## NLOPT_LD_SLSQP
## NLOPT_LD_LBFGS_NOCEDAL
## NLOPT_LD_LBFGS
## NLOPT_LN_PRAXIS
## NLOPT_LD_VAR1
## NLOPT_LD_VAR2
## NLOPT_LD_TNEWTON
## NLOPT_LD_TNEWTON_RESTART
## NLOPT_LD_TNEWTON_PRECOND
## NLOPT_LD_TNEWTON_PRECOND_RESTART
## NLOPT_GN_CRS2_LM
## NLOPT_GN_MLSL
## NLOPT_GD_MLSL
## NLOPT_GN_MLSL_LDS
## NLOPT_GD_MLSL_LDS
## NLOPT_LD_MMA
## NLOPT_LN_COBYLA
## NLOPT_LN_NEWUOA
## NLOPT_LN_NEWUOA_BOUND
## NLOPT_LN_NELDERMEAD
## NLOPT_LN_SBPLX
## NLOPT_LN_AUGLAG
## NLOPT_LD_AUGLAG
## NLOPT_LN_AUGLAG_EQ
## NLOPT_LD_AUGLAG_EQ
## NLOPT_LN_BOBYQA
## NLOPT_GN_ISRES
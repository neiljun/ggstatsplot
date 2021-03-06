#' @title Making text subtitle for contingency analysis (Pearson's chi-square
#'   test for independence for between-subjects design or McNemar's test for
#'   within-subjects design)
#' @name subtitle_contingency_tab
#' @author Indrajeet Patil
#'
#' @param main The variable to use as the **rows** in the
#'   contingency table.
#' @param condition The variable to use as the **columns** in the contingency
#'   table.
#' @param counts A string naming a variable in data containing counts, or `NULL`
#'   if each row represents a single observation (Default).
#' @param paired Logical indicating whether data came from a within-subjects
#'   design study (Default: `FALSE`). If `TRUE`, McNemar test subtitle will be
#'   returned. If `FALSE`, Pearson's chi-square test will be returned.
#' @param stat.title Title for the effect being investigated with the chi-square
#'   test. The default is `NULL`, i.e. no title will be added to describe the
#'   effect being shown. An example of a `stat.title` argument will be something
#'   like `"main x condition"` or `"interaction"`.
#' @inheritParams chisq_v_ci
#' @inheritParams subtitle_t_parametric
#' @inheritParams stats::chisq.test
#' @inheritParams subtitle_anova_parametric
#'
#' @importFrom tibble tribble as_tibble
#' @importFrom exact2x2 exact2x2
#' @importFrom tidyr uncount drop_na
#' @importFrom broom tidy
#' @importFrom jmv propTestN contTables contTablesPaired
#'
#' @seealso \code{\link{ggpiestats}}
#'
#' @examples
#'
#' # without counts data
#' subtitle_contingency_tab(
#'   data = mtcars,
#'   main = am,
#'   condition = cyl,
#'   nboot = 15
#' )
#'
#' # with counts data
#' # in case of no variation, a `NULL` will be returned.
#' library(jmv)
#'
#' as.data.frame(HairEyeColor) %>%
#'   dplyr::filter(.data = ., Sex == "Male") %>%
#'   subtitle_contingency_tab(
#'     data = .,
#'     main = Hair,
#'     condition = Sex,
#'     counts = Freq
#'   )
#' @export

# function body
subtitle_contingency_tab <- function(data,
                                     main,
                                     condition,
                                     counts = NULL,
                                     nboot = 100,
                                     paired = FALSE,
                                     stat.title = NULL,
                                     conf.level = 0.95,
                                     conf.type = "norm",
                                     simulate.p.value = FALSE,
                                     B = 2000,
                                     k = 2,
                                     messages = TRUE,
                                     ...) {
  ellipsis::check_dots_used()

  # =============================== dataframe ================================

  # creating a dataframe
  data <-
    dplyr::select(
      .data = data,
      main = !!rlang::enquo(main),
      condition = !!rlang::enquo(condition),
      counts = !!rlang::enquo(counts)
    ) %>%
    tidyr::drop_na(data = .)

  # main and condition need to be a factor for this analysis
  # also drop the unused levels of the factors

  # main
  data %<>%
    dplyr::mutate(.data = ., main = droplevels(as.factor(main))) %>%
    tibble::as_tibble(x = .)

  # condition
  if (!base::missing(condition)) {
    data %<>%
      dplyr::mutate(.data = ., condition = droplevels(as.factor(condition)))

    # in case there is no variation, no subtitle will be shown
    if (length(unique(levels(data$condition))) == 1L) {
      # display message
      base::message(cat(
        crayon::red("Error: "),
        crayon::blue("Row variable 'condition' contains less than 2 levels.\n"),
        crayon::blue("Chi-squared test can't be run; no subtitle displayed.\n"),
        sep = ""
      ))

      # assigning NULL to subtitle
      subtitle <- NULL

      # return early
      return(subtitle)
    }
  }

  # ============================ converting counts ===========================

  # untable the dataframe based on the count for each obervation
  if (!base::missing(counts)) {
    data %<>%
      tidyr::uncount(
        data = .,
        weights = counts,
        .remove = TRUE,
        .id = "id"
      ) %>%
      tibble::as_tibble(.)
  }

  # =============================== Pearson's chi-square =====================

  # sample size
  sample_size <- nrow(data)

  # running Pearson's Chi-square test of independence
  if (!isTRUE(paired)) {

    # object contatining stats
    stats_df <-
      broom::tidy(stats::chisq.test(
        x = data$main,
        y = data$condition,
        correct = FALSE,
        rescale.p = FALSE,
        simulate.p.value = simulate.p.value,
        B = B
      ))

    # computing confidence interval for Cramer's V
    effsize_df <- chisq_v_ci(
      data = data,
      rows = main,
      cols = condition,
      nboot = nboot,
      conf.level = conf.level,
      conf.type = conf.type
    )

    # message about effect size measure
    if (isTRUE(messages)) {
      effsize_ci_message(nboot = nboot, conf.level = conf.level)
    }

    # preparing subtitle
    subtitle <- subtitle_template(
      no.parameters = 1L,
      stat.title = stat.title,
      statistic.text = quote(italic(chi)^2),
      statistic = stats_df$statistic[[1]],
      parameter = stats_df$parameter[[1]],
      p.value = stats_df$p.value[[1]],
      effsize.text = quote(italic("V")),
      effsize.estimate = effsize_df$Cramer.V[[1]],
      effsize.LL = effsize_df$conf.low[[1]],
      effsize.UL = effsize_df$conf.high[[1]],
      n = sample_size,
      conf.level = conf.level,
      k = k,
      k.parameter = 0L
    )

    # ======================== McNemar's test =================================
  } else if (isTRUE(paired)) {
    # carrying out McNemar's test
    stats_df <-
      jmv::contTablesPaired(
        data = data,
        rows = "condition",
        cols = "main",
        counts = NULL,
        chiSq = TRUE,
        chiSqCorr = FALSE,
        exact = FALSE,
        pcRow = FALSE,
        pcCol = FALSE
      )

    # extracting needed information from jamovi object
    stats_df <- as.data.frame(stats_df$test)

    # computing exact odds ratio as effect size and their confidence interval
    effsize_df <-
      exact2x2::exact2x2(
        x = data$main,
        y = data$condition,
        or = 1,
        alternative = "two.sided",
        tsmethod = NULL,
        conf.int = TRUE,
        conf.level = conf.level,
        tol = 0.00001,
        conditional = TRUE,
        paired = TRUE,
        plot = FALSE,
        midp = FALSE
      )

    # converting to log odds
    effsize_df <- tibble::tribble(
      ~`estimate`,
      ~conf.low,
      ~conf.high,
      log(effsize_df$estimate[[1]]),
      log(effsize_df$conf.int[1]),
      log(effsize_df$conf.int[2])
    )

    # preparing subtitle
    subtitle <- subtitle_template(
      no.parameters = 1L,
      stat.title = stat.title,
      statistic.text = quote(italic(chi)^2),
      statistic = stats_df$`value[mcn]`[[1]],
      parameter = stats_df$`df[mcn]`[[1]],
      p.value = stats_df$`p[mcn]`[[1]],
      effsize.text = quote("log"["e"](OR)),
      effsize.estimate = effsize_df$estimate[[1]],
      effsize.LL = effsize_df$conf.low[[1]],
      effsize.UL = effsize_df$conf.high[[1]],
      n = sample_size,
      conf.level = conf.level,
      k = k,
      k.parameter = 0L
    )
  }

  # return the subtitle
  return(subtitle)
}


#' @title Making text subtitle for Proportion Test (N Outcomes)
#' @description This is going to be a chi-squared Goodness of fit test.
#' @name subtitle_onesample_proptest
#' @author Indrajeet Patil
#'
#' @param ratio A vector of numbers: the expected proportions for the proportion
#'   test. Default is `NULL`, which means if there are two levels `ratio =
#'   c(1,1)`, etc.
#' @param legend.title Title text for the legend.
#' @inheritParams subtitle_contingency_tab
#'
#' @examples
#'
#' # with counts
#' library(jmv)
#'
#' subtitle_onesample_proptest(
#'   data = as.data.frame(HairEyeColor),
#'   main = Eye,
#'   counts = Freq
#' )
#'
#' # in case no variation, only sample size will be shown
#' subtitle_onesample_proptest(
#'   data = cbind.data.frame(x = rep("a", 10)),
#'   main = x
#' )
#' @export

# defining the function
subtitle_onesample_proptest <- function(data,
                                        main,
                                        counts = NULL,
                                        ratio = NULL,
                                        legend.title = NULL,
                                        k = 2,
                                        ...) {
  ellipsis::check_dots_used()

  # saving the column label for the 'main' variables
  if (is.null(legend.title)) {
    legend.title <- rlang::as_name(rlang::ensym(main))
  }

  # ============================ dataframe ===============================

  # creating a dataframe
  data <-
    dplyr::select(
      .data = data,
      main = !!rlang::enquo(main),
      counts = !!rlang::enquo(counts)
    ) %>%
    tidyr::drop_na(data = .)

  # ====================== converting counts ================================

  # untable the dataframe based on the count for each obervation
  if (!base::missing(counts)) {
    data %<>%
      tidyr::uncount(
        data = .,
        weights = counts,
        .remove = TRUE,
        .id = "id"
      ) %>%
      tibble::as_tibble(x = .)
  }

  # ============================= statistical test =========================

  # sample size
  sample_size <- nrow(data)

  # conducting proportion test with jmv::propTestN()
  stats_df <-
    jmv::propTestN(
      data = data,
      var = "main",
      ratio = ratio,
      expected = FALSE
    )

  # extracting the results
  stats_df <- tibble::as_tibble(as.data.frame(stats_df$tests))

  # if there is no value corresponding to one of the levels of the 'main'
  # variable, then no subtitle is needed
  if (is.nan(stats_df$chi[[1]])) {
    subtitle <-
      base::substitute(
        expr =
          paste(
            italic("n"),
            " = ",
            n
          ),
        env = base::list(n = sample_size)
      )

    # display message
    base::message(cat(
      crayon::red("Warning: "),
      crayon::blue("Proportion test will not be run because it requires "),
      crayon::yellow(legend.title),
      crayon::blue(" to have at least \n2 levels with non-zero frequencies.\n"),
      sep = ""
    ))
  } else {
    # preparing proportion test subtitle for the plot
    subtitle <-
      base::substitute(
        expr =
          paste(
            italic(chi)^2,
            "(",
            df,
            ") = ",
            estimate,
            ", ",
            italic("p"),
            " = ",
            p.value,
            ", ",
            italic("n"),
            " = ",
            n
          ),
        env = base::list(
          estimate = specify_decimal_p(x = stats_df$chi[[1]], k = k),
          df = stats_df$df[[1]],
          p.value = specify_decimal_p(x = stats_df$p[[1]], k = k, p.value = TRUE),
          n = sample_size
        )
      )
  }

  # return the subtitle text
  return(subtitle)
}

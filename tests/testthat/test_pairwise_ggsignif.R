# context -------------------------------------------------------------------
context(desc = "pairwise_p with ggsignif")

# significant display works -------------------------------------------------

testthat::test_that(
  desc = "check comparison significant displays - adjusted",
  code = {

    # creating the plot
    set.seed(123)
    p <- ggstatsplot::ggbetweenstats(
      data = ggplot2::msleep,
      x = vore,
      y = brainwt,
      messages = FALSE,
      pairwise.comparisons = TRUE,
      caption = "mammalian sleep",
      k = 3
    )

    # checking dimensions of data
    data_dims <- dim(p$plot_env$df_pairwise)

    testthat::expect_equal(data_dims[1], 0L)
    testthat::expect_equal(data_dims[2], 12L)

    # checking caption
    testthat::expect_identical(
      p$labels$caption,
      ggplot2::expr(atop(
        displaystyle("mammalian sleep"),
        expr = paste(
          "Pairwise comparisons: ",
          bold("Games-Howell test"),
          "; Adjustment (p-value): ",
          bold("Holm")
        )
      ))
    )
  }
)


# non-significant display works ---------------------------------------------

testthat::test_that(
  desc = "check non-significant comparison displays - no adjustment",
  code = {

    # creating the plot
    set.seed(123)
    p <- ggstatsplot::ggbetweenstats(
      data = ggstatsplot::movies_wide,
      x = mpaa,
      y = votes,
      messages = FALSE,
      pairwise.comparisons = TRUE,
      p.adjust.method = "none",
      pairwise.display = "ns",
      pairwise.annotation = "p.value",
      k = 3
    )

    # data used for pairwise comparisons
    dat <- p$plot_env$df_pairwise

    # ggsignif layer parameters
    ggsignif_stat <- p$layers[[6]]$stat_params

    # checking dimensions of data
    data_dims <- dim(dat)

    testthat::expect_equal(data_dims[1], 6L)
    testthat::expect_equal(data_dims[2], 12L)

    # checking comparison groups and labels
    testthat::expect_identical(dat$group1[1], "PG")
    testthat::expect_identical(dat$group2[1], "NC-17")
    testthat::expect_identical(dat$groups[[1]], c("PG", "NC-17"))
    testthat::expect_identical(dat$label[6], "p = 0.482")
    testthat::expect_identical(
      p$labels$caption,
      ggplot2::expr(atop(
        displaystyle(NULL),
        expr = paste(
          "Pairwise comparisons: ",
          bold("Games-Howell test"),
          "; Adjustment (p-value): ",
          bold("None")
        )
      ))
    )
    testthat::expect_identical(
      ggstatsplot::specify_decimal_p(
        x = dat$p.value[1],
        p.value = TRUE,
        k = 4
      ),
      "0.6400"
    )

    # checking values
    testthat::expect_equal(dat$mean.difference[1], -2756.112, tolerance = 1e-3)
    testthat::expect_equal(dat$mean.difference[6], -3059.195, tolerance = 1e-3)

    # checking ggsignif layers
    testthat::expect_equal(ggsignif_stat$y_position[1], 161548.2, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[3], 180460.6, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[6], 208829.1, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$comparisons[[4]], c("PG-13", "NC-17"))
    testthat::expect_equal(
      ggsignif_stat$annotations,
      c(
        "p = 0.640",
        "p = 0.063",
        "p = 0.313",
        "p = 0.149",
        "p = 0.995",
        "p = 0.482"
      )
    )
  }
)

# mixed display works -------------------------------------------------

testthat::test_that(
  desc = "check mixed comparison displays - adjusted",
  code = {

    # creating the plot
    set.seed(123)
    p <- ggstatsplot::ggbetweenstats(
      data = dplyr::sample_frac(ggstatsplot::movies_long, size = 0.5),
      x = genre,
      y = rating,
      type = "np",
      messages = FALSE,
      pairwise.comparisons = TRUE,
      p.adjust.method = "fdr",
      pairwise.display = "all",
      k = 3
    )

    # data used for pairwise comparisons
    dat <- p$plot_env$df_pairwise

    # ggsignif layer parameters
    ggsignif_stat <- p$layers[[6]]$stat_params

    # checking dimensions of data
    data_dims <- dim(dat)

    testthat::expect_equal(data_dims[1], 15L)
    testthat::expect_equal(data_dims[2], 7L)

    # checking comparison groups and labels
    testthat::expect_identical(dat$group1[1], "Action")
    testthat::expect_identical(dat$group2[12], "Romance")
    testthat::expect_identical(dat$groups[[1]], c("Action", "Animation"))
    testthat::expect_identical(dat$label[1], "ns")
    testthat::expect_identical(dat$label[4], "***")
    testthat::expect_identical(dat$label[15], "***")
    testthat::expect_identical(dat$p.value.label[15], "p <= 0.001")
    testthat::expect_identical(dat$p.value.label[6], "p = 0.058")
    testthat::expect_identical(
      p$labels$caption,
      ggplot2::expr(atop(
        displaystyle(NULL),
        expr = paste(
          "Pairwise comparisons: ",
          bold("Dwass-Steel-Crichtlow-Fligner test"),
          "; Adjustment (p-value): ",
          bold("Benjamini & Hochberg")
        )
      ))
    )
    testthat::expect_identical(
      ggstatsplot::specify_decimal_p(
        x = dat$p.value[6],
        p.value = TRUE,
        k = 4
      ),
      "0.0577"
    )

    # checking values
    testthat::expect_equal(dat$W[1], 2.82, tolerance = 0.01)
    testthat::expect_equal(dat$W[6], -3.37, tolerance = 0.01)

    # checking ggsignif layers
    testthat::expect_equal(ggsignif_stat$y_position[1], 9.327500, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[3], 10.120357, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[15], 14.877500, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$comparisons[[15]], c("Drama", "Romance"))
    testthat::expect_equal(
      ggsignif_stat$annotations,
      c(
        "ns",
        "ns",
        "ns",
        "***",
        "ns",
        "ns",
        "ns",
        "ns",
        "ns",
        "ns",
        "***",
        "ns",
        "ns",
        "ns",
        "***"
      )
    )
  }
)


# robust test works -------------------------------------------------

testthat::test_that(
  desc = "check robust test display - adjusted",
  code = {

    # creating the plot
    set.seed(123)
    p <- ggstatsplot::ggbetweenstats(
      data = ggplot2::mpg,
      x = drv,
      y = cty,
      messages = FALSE,
      k = 3,
      type = "r",
      nboot = 20,
      pairwise.comparisons = TRUE,
      pairwise.display = "s",
      pairwise.annotation = "p.value"
    )

    # data used for pairwise comparisons
    dat <- p$plot_env$df_pairwise

    # ggsignif layer parameters
    ggsignif_stat <- p$layers[[6]]$stat_params

    # checking dimensions of data
    data_dims <- dim(dat)

    testthat::expect_equal(data_dims[1], 2L)
    testthat::expect_equal(data_dims[2], 9L)

    # checking comparison groups and labels
    testthat::expect_identical(dat$group1[1], "4")
    testthat::expect_identical(dat$group2[2], "r")
    testthat::expect_identical(dat$groups[[1]], c("4", "f"))
    testthat::expect_identical(dat$significance[1], "***")
    testthat::expect_identical(
      p$labels$caption,
      ggplot2::expr(atop(
        displaystyle(NULL),
        expr = paste(
          "Pairwise comparisons: ",
          bold("Yuen's trimmed means test"),
          "; Adjustment (p-value): ",
          bold("Holm")
        )
      ))
    )
    testthat::expect_identical(
      ggstatsplot::specify_decimal_p(
        x = dat$ci.lower[1],
        p.value = FALSE,
        k = 2
      ),
      "-6.43"
    )

    # checking values
    testthat::expect_equal(dat$psihat[1], -5.38, tolerance = 0.01)
    testthat::expect_equal(dat$psihat[2], 5.57, tolerance = 0.01)

    # checking ggsignif layers
    testthat::expect_equal(ggsignif_stat$y_position[1], 35.875, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[2], 37.825, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[3], 39.775, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$comparisons[[2]], c("f", "r"))
    testthat::expect_equal(
      ggsignif_stat$annotations,
      c(
        "p <= 0.001",
        "p <= 0.001"
      )
    )
  }
)


# student's t test works -------------------------------------------------

testthat::test_that(
  desc = "check student's t test display - adjusted",
  code = {

    # creating the plot
    set.seed(123)
    p <- ggstatsplot::ggbetweenstats(
      data = mtcars,
      x = cyl,
      y = wt,
      messages = FALSE,
      k = 3,
      type = "p",
      p.adjust.method = "bonferroni",
      nboot = 50,
      var.equal = TRUE,
      pairwise.comparisons = TRUE,
      pairwise.display = "everything",
      pairwise.annotation = "p"
    )

    # data used for pairwise comparisons
    dat <- p$plot_env$df_pairwise

    # ggsignif layer parameters
    ggsignif_stat <- p$layers[[6]]$stat_params

    # checking dimensions of data
    data_dims <- dim(dat)

    testthat::expect_equal(data_dims[1], 3L)
    testthat::expect_equal(data_dims[2], 9L)

    # checking comparison groups and labels
    testthat::expect_identical(dat$group1[1], "6")
    testthat::expect_identical(dat$group2[2], "4")
    testthat::expect_identical(dat$groups[[1]], c("6", "4"))
    testthat::expect_identical(dat$significance[1], "*")
    testthat::expect_identical(dat$significance[2], "***")
    testthat::expect_identical(dat$significance[3], "*")
    testthat::expect_identical(p$labels$caption,
                               ggplot2::expr(atop(
                                 displaystyle(NULL),
                                 expr = paste(
                                   "Pairwise comparisons: ",
                                   bold("Student's t-test"),
                                   "; Adjustment (p-value): ",
                                   bold("Bonferroni")
                                 )
                               )))

    # checking values
    testthat::expect_equal(dat$mean.difference[1], 0.831, tolerance = 0.01)
    testthat::expect_equal(dat$mean.difference[3], 0.882, tolerance = 0.01)
    testthat::expect_equal(dat$conf.low[1], 0.0794, tolerance = 0.01)
    testthat::expect_equal(dat$conf.high[1],1.580, tolerance = 0.01)

    # checking ggsignif layers
    testthat::expect_equal(ggsignif_stat$y_position[1], 5.559600, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[2], 5.852925, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$y_position[3], 6.146250, tolerance = 0.01)
    testthat::expect_equal(ggsignif_stat$comparisons[[2]], c("8", "4"))
    testthat::expect_equal(
      ggsignif_stat$annotations,
      c(
        "p = 0.032",
        "p <= 0.001",
        "p = 0.015"
      )
    )
  }
)
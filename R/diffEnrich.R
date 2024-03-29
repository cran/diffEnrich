#' diffEnrich
#' @description This function takes the objects generated from \code{\link{pathEnrich}}.
#' If performing a dfferential enrichment analysis, the user will have 2 objects. There
#' will be one for the genes of interest in gene list 1 and one for the genes of interest in gene list 2 (see example for \code{\link{pathEnrich}}).
#' This function then uses a Fisher's Exact test to identify differentially enriched
#' pathways between the terms enriched in the gene-of-interest lists. \code{diffEnrich}
#' will remove KEGG pathways that do not contain any genes from either gene list as these
#' cannot be tested, and will print a warning message telling the user how many pathways
#' were removed.
#' \code{diffEnrich} returns a dataframe containing differentially enriched
#' pathways with their associated estimated odds ratio, unadjusted p-value, and fdr adjusted
#' p-value. S3 generic functions for \code{print} and \code{summary} are
#' provided. The \code{print} function prints the results table as a \code{tibble}, and the
#' \code{summary} function returns the number of pathways that reached statistical significance
#' as well as their descriptions, the number of genes used from the KEGG data base, the KEGG species,
#' the number of pathways that were shared (and therefore tested) between the gene lists and the
#' method used for multiple testing correction.
#'
#' @param list1_pe object of class \code{pathEnrich} generated from \code{\link{pathEnrich}}.
#' See example for \code{\link{pathEnrich}}.
#' @param list2_pe object of class \code{pathEnrich} generated from \code{\link{pathEnrich}}.
#' See example for \code{\link{pathEnrich}}.
#' @param method character. Character string telling \code{diffEnrich} which method to
#' use for multiple testing correction. Available methods are thos provided by
#' \code{\link{p.adjust}}, and the default is "BH", or False Discovery Rate (FDR).
#' @param cutoff Numeric. The p-value threshold to be used as the cutoff when determining statistical significance, and used to filter list of significant pathways.
#'
#' @return A list object of class \code{diffEnrich} that contains 5 items:
#'
#' \describe{
#' \item{species}{The species used in enrichment}
#' \item{padj}{The method used to correct for multiple testing for the differential enrichment}
#' \item{sig_paths}{The KEGG pathways the reached statistical significance after multiple testing correction.}
#' \item{path_intersect}{the number of pathways that were shared (and therefore tested) between the gene lists.}
#' \item{de_table}{A data frame that summarizes the results of the differential enrichment analysis and contains the following variables:}
#' }
#'
#' \describe{
#'   \item{KEGG_PATHWAY_ID}{KEGG Pathway Identifier}
#'   \item{KEGG_PATHWAY_description}{Description of KEGG Pathway (provided by KEGG)}
#'   \item{KEGG_PATHWAY_cnt}{Number of Genes in KEGG Pathway}
#'   \item{KEGG_DATABASE_cnt}{Number of Genes in KEGG Database}
#'   \item{KEGG_PATHWAY_in_list1}{Number of Genes from gene list 1 in KEGG Pathway}
#'   \item{KEGG_DATABASE_in_list1}{Number of Genes from gene list 1 in KEGG Database}
#'   \item{expected_list1}{Expected number of genes from list 1 to be in KEGG pathway by chance (i.e., not enriched)}
#'   \item{enrich_p_list1}{P-value for enrichment of list 1 genes related to KEGG pathway}
#'   \item{p_adj_list1}{Multiple testing adjustment of enrich_p_list1 (default = False Discovery Rate (Benjamini and Hochberg))}
#'   \item{fold_enrichment_list1}{KEGG_PATHWAY_in_list1/expected_list1}
#'   \item{KEGG_PATHWAY_in_list2}{Number of Genes from gene list 2 in KEGG Pathway}
#'   \item{KEGG_DATABASE_in_list2}{Number of Genes from gene list 2 in KEGG Database}
#'   \item{expected_list2}{Expected number of genes from list 2 to be in KEGG pathway by chance (i.e., not enriched)}
#'   \item{enrich_p_list2}{P-value for enrichment of list 2 genes related to KEGG pathway}
#'   \item{p_adj_list2}{Multiple testing adjustment of enrich_p_list2 (default = False Discovery Rate (Benjamini and Hochberg))}
#'   \item{fold_enrichment_list2}{KEGG_PATHWAY_in_list2/expected_list2}
#'   \item{odd_ratio}{Odds of a gene from list 2 being from this KEGG pathway / Odds of a gene from list 1 being from this KEGG pathway}
#'   \item{diff_enrich_p}{P-value for differential enrichment of this KEGG pathway between list 1 and list 2}
#'   \item{diff_enrich_adjusted}{Multiple testing adjustment of diff_enrich_p (default = False Discovery Rate (Benjamini and Hochberg))}
#' }
#'
#' @export
#' @importFrom  stats fisher.test
#' @importFrom  rlang .data
#' @import dplyr
#'
#' @examples
#' ## Generate individual enrichment reults
#' list1_pe <- pathEnrich(gk_obj = kegg, gene_list = geneLists$list1)
#' list2_pe <- pathEnrich(gk_obj = kegg, gene_list = geneLists$list2)
#'
#' ## Perform differential enrichment
#' dif_enrich <- diffEnrich(list1_pe = list1_pe, list2_pe = list2_pe, method = 'none', cutoff = 0.05)
#'
diffEnrich <- function(list1_pe, list2_pe, method = 'BH', cutoff = 0.05){
  ## check class
  # if(class(list1_pe) != "pathEnrich"){stop("list1_pe must be an object of class 'pathEnrich'. Please generate this object using the pathEnrich function provided in this package.")}
  if(inherits(list1_pe, "pathEnrich") != TRUE){stop("list1_pe must be an object of class 'pathEnrich'. Please generate this object using the pathEnrich function provided in this package.")}
  # if(class(list2_pe) != "pathEnrich"){stop("list2_pe must be an object of class 'pathEnrich'. Please generate this object using the pathEnrich function provided in this package.")}
  if(inherits(list2_pe, "pathEnrich") != TRUE){stop("list2_pe must be an object of class 'pathEnrich'. Please generate this object using the pathEnrich function provided in this package.")}
  ## Call .combineEnrich helper function
  ce <- .combineEnrich(list1_pe = list1_pe, list2_pe = list2_pe)
  # define p.adjust method
  p.adj <- method

  ## Build diffEnrich Fisher's Exact function
  de <- function(a,b,c,d){
    y <- stats::fisher.test(matrix(c(a,b,c-a,d-b), nrow = 2))
    est <- y$estimate
    pv <- y$p.value
    out.de <- data.frame(est, pv)
    return(out.de)
  }
  ## perform differential enrichment
  res <- cbind(ce, do.call('rbind', apply(ce[, c("KEGG_PATHWAY_in_list2", "KEGG_PATHWAY_in_list1",
                                                 "KEGG_DATABASE_in_list2", "KEGG_DATABASE_in_list1")], 1,
               function(a){ de(a[1], a[2], a[3], a[4])})))
  res$adjusted_p <- stats::p.adjust(res$pv, method = method)
  colnames(res) <- c("KEGG_PATHWAY_ID", "KEGG_PATHWAY_description", "KEGG_PATHWAY_cnt", "KEGG_DATABASE_cnt",
                     "KEGG_PATHWAY_in_list1", "KEGG_DATABASE_in_list1", "expected_list1", "enrich_p_list1",
                     "p_adj_list1", "fold_enrichment_list1", "KEGG_PATHWAY_in_list2", "KEGG_DATABASE_in_list2", "expected_list2",
                     "enrich_p_list2", "p_adj_list2", "fold_enrichment_list2", "odd_ratio", "diff_enrich_p", "diff_enrich_adjusted")

  ## re-order table based on adjusted p-value
  # library(dplyr)
  de_table <- res %>%
    arrange(.data$diff_enrich_adjusted)

  ## update rownames
  rownames(de_table) <- de_table$KEGG_PATHWAY_ID

  ## define species
  species <- unlist(strsplit(de_table$KEGG_PATHWAY_description[1], split = " - ", fixed = TRUE))[2]

  ## define pathway intersect
  path_intersect <- dim(de_table)[1]

  ## Extract sicgnificant pathways
  sig_paths <- de_table %>%
    dplyr::filter(.data$diff_enrich_adjusted < cutoff) %>%
    pull(.data$KEGG_PATHWAY_description)
  sig_paths <- unlist(lapply(strsplit(sig_paths, split = " - ", fixed = TRUE), function(x) x[1]))

  ## build results list
  out <- list("species" = species,
              "padj" = p.adj,
              "cutoff" = cutoff,
              "path_intersect" = path_intersect,
              "de_table" = de_table,
              "sig_pathways" = sig_paths)
  ## define class attr
  class(out) <- c("diffEnrich")
  return(out)
}



#' .combineEnrich
#' @description This is a helper function for \code{diffEnrich}. This function takes the objects generated from \code{\link{pathEnrich}}.
#' If performing a dfferential enrichment analysis, the user will have 2 objects. There
#' will be one for list1 and one for list2(see example for \code{\link{pathEnrich}}).
#' This function then merges the two data frames using the following columns that should be present
#' in both objects (\code{by = c("KEGG_PATHWAY_ID", "KEGG_PATHWAY_description", "KEGG_PATHWAY_cnt", "KEGG_DATABASE_cnt")}). This merged data frame
#' will be used as the input for the differential enrichment function. Any pathways that do not contain any genes from either gene list will be removed.
#'
#' @param list1_pe object of class \code{pathEnrich} generated from \code{\link{pathEnrich}}.
#' See example for \code{\link{pathEnrich}}.
#' @param  list2_pe object of class \code{pathEnrich} generated from \code{\link{pathEnrich}}.
#' See example for \code{\link{pathEnrich}}.
#'
#' @return combined_enrich: An object of class data.frame that is the result of merging
#' \code{list1_pe} and \code{list2_pe}, using the default joining implemented in the base
#' \code{\link{merge}} function.
#'
#'
.combineEnrich <- function(list1_pe, list2_pe){
  ## argument check
  if(missing(list1_pe)){stop("Argument missing: list1_pe")}
  if(missing(list2_pe)){stop("Argument missing: list2_pe")}

  ## Merge results from first enrichment
  combined_enrich.tmp <- merge(list1_pe$enrich_table, list2_pe$enrich_table, by = c("KEGG_PATHWAY_ID", "KEGG_PATHWAY_description", "KEGG_PATHWAY_cnt", "KEGG_DATABASE_cnt"))
  ## remove pathways that have 0 genes in both lists
  combined_enrich <- combined_enrich.tmp %>%
    dplyr::filter(!(.data$KEGG_PATHWAY_in_list.x == 0 & .data$KEGG_PATHWAY_in_list.y == 0))

  ## get number of pathways that were removed
  paths_removed <- dim(combined_enrich.tmp)[1] - dim(combined_enrich)[1]

  if(list1_pe$N == 0 & list2_pe$N == 0){warning(paste0("KEGG pathways that do not contain any genes from either list provided will be removed as these cannot be tested.",
                                                       paths_removed, " pathways were removed."))}

  colnames(combined_enrich) <- gsub(".x", "_list1", colnames(combined_enrich), fixed = TRUE)
  colnames(combined_enrich) <- gsub(".y", "_list2", colnames(combined_enrich), fixed = TRUE)
  colnames(combined_enrich) <- c("KEGG_PATHWAY_ID", "KEGG_PATHWAY_description", "KEGG_PATHWAY_cnt", "KEGG_DATABASE_cnt",
                                 "KEGG_PATHWAY_in_list1", "KEGG_DATABASE_in_list1", "expected_list1", "enrich_p_list1",
                                 "p_adj_list1", "fold_enrichment_list1", "KEGG_PATHWAY_in_list2", "KEGG_DATABASE_in_list2", "expected_list2",
                                 "enrich_p_list2", "p_adj_list2", "fold_enrichment_list2")

  out <- combined_enrich
  return(out)
}


#' @name print.diffEnrich
#' @rdname diffEnrich
#' @method print diffEnrich
#' @param x object of class \code{diffEnrich}
#' @param \dots Unused
#' @export
print.diffEnrich <- function(x, ...){
  dplyr::as_tibble(x$de_table)
}

#' @name summary.diffEnrich
#' @rdname diffEnrich
#' @method summary diffEnrich
#' @param object object of class \code{diffEnrich}
#' @export
summary.diffEnrich <- function(object, ...){
  ## summary part 1
  l1 <- paste0(
    object$path_intersect, ' KEGG pathways were shared between gene lists and were tested. \n')
  l2 <- paste0("KEGG pathway species: ", object$species, "\n")
  l3 <- paste0(
    object$de_table$KEGG_DATABASE_cnt[1], ' genes from gene_list were in the KEGG data pull. \n')
  l4 <- paste0("p-value adjustment method: ", object$padj, "\n")
  l5 <- paste0(length(object$sig_pathways), " pathways reached statistical significance after multiple testing correction at a cutoff of ", object$cutoff, ". \n")
  cat(
    l1, l2, l3, l4, l5, "\n")
  ## summary part 2
  paths <- paste(object$sig_pathways, collapse = "\n")
  cat("Significant pathways: \n", paths)
}

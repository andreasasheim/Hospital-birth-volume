# Hospital-birth-volume

Files for project "How do hospital birth volumes and travel time to hospital impact birth outcomes?"

The analysis protocol was uploaded on May 10th 2022. Up to this point, a rough implementation of the analysis code had been implementet, and the balance of the design had been checked, but no results on patient outcomes had been obtained. 

The preprint at https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4309610 was published without the supplementary materials, which is found here.



The code is organised with a set of do-files with prefix makelist, that assembles pieces needed to make the analysis file, e.g., which municipalities that share borders and size of hospitals. The do-files analysisfile_* do the final assembly. The do-file analysis_nonlinear contains an example of how a spline regression is done for the paper.

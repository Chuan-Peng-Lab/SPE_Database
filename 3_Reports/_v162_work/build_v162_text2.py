# -*- coding: utf-8 -*-
"""Batch 2: rewrite the three example sections + discussion with the v2 results."""
import docx

DST = r'D:\GitHub_programe\GitHub\SPE_Database\Datasets\4_Writing\SPE_数据库_v16.2.docx'
doc = docx.Document(DST)


def set_par(i, text):
    p = doc.paragraphs[i]
    if not p.runs:
        p.add_run(text); return
    p.runs[0].text = text
    for r in p.runs[1:]:
        r.text = ""


E = {}

# ------------------------------------------------ Example 1: method paragraph
E[49] = (
    "The self-prioritization effect (SPE) is typically quantified as the performance difference "
    "between self-referential and other-referential conditions. However, different categories of "
    "others have been used as baseline conditions when estimating SPE magnitude. Existing studies "
    "have yielded inconsistent estimates of the self-prioritization effect (SPE) magnitude. "
    "Nevertheless, a systematic examination of how baseline selection affects SPE magnitude remains "
    "lacking. Leveraging the large-scale sample size of the SPE database, we compared the effect "
    "size of the SPE across five standardized baselines (Sun et al., 2023): Non-person, Stranger, "
    "Celebrity, Acquaintance, and Close Other. Standardized effect sizes (Cohen's d) were computed "
    "at the participant level by contrasting self-related trials against each baseline condition "
    "separately, using a pooled standard deviation. Reaction-time based effect sizes were computed "
    "on correct trials with response times above 0 ms and no longer than 10,000 ms; accuracy-based "
    "effect sizes were computed on trials with a valid response (0 = error, 1 = correct). Because "
    "participant identifiers are unique only within a dataset, participants were nested within "
    "datasets (that is, the random effect was defined on the dataset-by-participant key). A linear "
    "mixed-effects model without intercept was then fitted to the participant-level Cohen's d "
    "values, with this nested participant term as a random intercept and data source as an "
    "additional variance component. From this model, 10,000 multivariate normal samples were drawn "
    "from the estimated fixed-effects distribution to obtain the posterior-like distributions of "
    "each identity's SPE magnitude. For consistency, we use positive Cohen's d for SPE (i.e., "
    "faster reaction times or higher accuracy for self relative to other identities). "
)

E[51] = ("Figure 4. Self-prioritization effects along the social distance continuum and pairwise "
         "comparisons across social identities.")

# ------------------------------------------------ Example 1: results
E[52] = (
    "For reaction time (RT), the SPE was positive for all five baseline conditions: every "
    "bootstrap distribution of the participant-level Cohen's d lay entirely above zero (all 95% "
    "confidence intervals excluded zero; see Figure 4A). The magnitude of the SPE, however, "
    "differed only between some baselines (see Figure 4). To test whether the magnitude differed "
    "statistically between SPEs calculated with different baselines, we computed these effect sizes "
    "pairwise (\u0394 = dA \u2212 dB) using the same model-based sampling approach, and inferred a "
    "difference when the bootstrap 95% CI excluded zero (see Figure 4C and 4D). "
)

E[53] = (
    "For RT, 3 of the 10 pairwise comparisons were statistically significant, and all three "
    "involved Close others as the baseline. The Non-person-based SPE was larger than the "
    "Close-other-based SPE (\u0394 = 0.089, 95% CI [0.051, 0.126], p < .001); the Celebrity-based "
    "SPE was larger than the Close-other-based SPE (\u0394 = 0.078, 95% CI [0.022, 0.134], "
    "p = .007); and the Stranger-based SPE was larger than the Close-other-based SPE "
    "(\u0394 = 0.071, 95% CI [0.055, 0.088], p < .001). The remaining seven comparisons were not "
    "statistically significant, including all comparisons among Non-person, Stranger, and Celebrity "
    "(all |\u0394| \u2264 0.018, all ps \u2265 .372) and the Acquaintance-versus-Close-other "
    "comparison (\u0394 = 0.005, 95% CI [\u22120.076, 0.087], p = .910)."
)

E[54] = (
    "Six of the 10 pairwise comparisons reached statistical significance for accuracy (ACC). The "
    "Non-person-based SPE was larger than that based on Close others (\u0394 = 0.122, 95% CI "
    "[0.098, 0.146], p < .001), Acquaintances (\u0394 = 0.077, 95% CI [0.022, 0.133], p = .006), "
    "Strangers (\u0394 = 0.071, 95% CI [0.046, 0.097], p < .001), and Celebrities (\u0394 = 0.055, "
    "95% CI [0.011, 0.099], p = .014). The Celebrity-based SPE was larger than the "
    "Close-other-based SPE (\u0394 = 0.067, 95% CI [0.031, 0.103], p < .001), and the "
    "Stranger-based SPE was larger than the Close-other-based SPE (\u0394 = 0.051, 95% CI [0.040, "
    "0.061], p < .001). The remaining four comparisons were not significant: Stranger versus "
    "Celebrity (\u0394 = \u22120.016, 95% CI [\u22120.054, 0.021], p = .386), Stranger versus "
    "Acquaintance (\u0394 = 0.006, 95% CI [\u22120.047, 0.059], p = .827), Celebrity versus "
    "Acquaintance (\u0394 = 0.022, 95% CI [\u22120.042, 0.085], p = .494), and Acquaintance versus "
    "Close other (\u0394 = 0.045, 95% CI [\u22120.008, 0.097], p = .096)."
)

E[55] = (
    "Taken together, the estimated magnitude of the SPE was reliably positive against every "
    "baseline, but the baselines did not order themselves along a clear social-distance gradient. "
    "Across both RT and ACC, the only consistent contrast was between the baselines with the "
    "largest and the smallest point estimates: the Non-person-based (and, for RT, also the "
    "Stranger- and Celebrity-based) SPE exceeded the Close-other-based SPE, whereas the comparisons "
    "among Non-person, Stranger, and Celebrity were not reliable in either measure. Two caveats are "
    "important. First, the baselines differed markedly in coverage: Non-person and Celebrity were "
    "represented by only 8 and 3 datasets respectively, whereas Stranger and Close others were "
    "represented by 70 and 50 datasets, so the absence of reliable differences among the more "
    "sparsely covered baselines should be interpreted with caution. Second, this pattern qualifies "
    "rather than confirms the proposal that the SPE follows a monotonic gradient of closeness to "
    "the self (Aron et al., 1992; Markus & Kitayama, 1991). "
)

# ------------------------------------------------ Example 2: method numbers
E[58] = (
    " Leveraging the large sample size of the current database (89 experiment-level datasets, "
    "1,068,081 nonmatching trials, 4,520 participants), we estimated the SPE using a bootstrap "
    "resampling approach (500 iterations per sample size, with replacement) that allows evaluation "
    "of effect size stability across increasing sample sizes. Recall that in the self-matching "
    "task, each trial presents a shape\u2013label pair. Thus, for matching trials, the shape and "
    "label are congruent (e.g., a shape previously associated with \"Self\" paired with the word "
    "\"Self\"), making the distinction between self-related and other-related trials "
    "straightforward. For nonmatching conditions (also referred to as incongruent or mismatching "
    "trials), however, the shape and label convey conflicting identity information (e.g., a shape "
    "for \"Self\" paired with the word \"Stranger\"), creating difficulty in defining what "
    "constitutes a \"Self\" trial. Reaction-time based Cohen's d values were computed on correct "
    "trials with response times above 0 ms and no longer than 10,000 ms, accuracy-based Cohen's d "
    "values on trials with a valid response (0 = error, 1 = correct), and participants were again "
    "identified by the dataset-by-participant key. "
)

E[61] = (
    "To fully exploit the available datasets while preserving interpretability, we implemented both "
    "conservative and liberal approach for estimating the SPE for nonmatching trials. The "
    "conservative approach only include pure self versus non-self contrasts: only participants from "
    "experiments involving at least three distinct identities were eligible for inclusion. At the "
    "trial level, additional filtering procedures were applied. For shape-based SPE, nonmatching "
    "trials in which the shape corresponded to a non-self identity but the label referred to the "
    "Self were excluded. Conversely, for label-based SPE, trials in which the label corresponded to "
    "a non-self identity but the shape was associated with the Self were removed. Using these "
    "criteria, 38 datasets contributed to the conservative shape-based analysis (1,977 eligible "
    "participants) and 27 datasets to the conservative label-based analysis (1,565 eligible "
    "participants). The final datasets comprised 371,894 trials for the shape-based SPE and 276,010 "
    "trials for the label-based SPE. The liberal approach retained 85 datasets (5,149 participants, "
    "724,323 trials) for the shape-based SPE and 69 datasets (4,487 participants, 628,024 trials) "
    "for the label-based SPE."
)

E[62] = (
    " In contrast, the liberal approach maximized dataset coverage by retaining all eligible "
    "experiments and nonmatching trials regardless of the presence of residual self-referential "
    "information in the comparison condition. To ensure a fair comparison between shape-based and "
    "label-based SPE for nonmatching trials, we aligned sample-size by using the minimum N of the "
    "shape- and label-based SPE for the conservative approach (see Table 2 for the bootstrap "
    "sample sizes and the results of the two approaches)."
)

# ------------------------------------------------ Example 2: figure/table captions
E[64] = (
    "Figure 5. Bootstrap estimation of the self-prioritization effect under nonmatching conditions. "
    "A and B, the conservative approach; C and D, the liberal approach."
)
E[65] = "Table 2"
E[66] = "Bootstrap Estimates of the Self-Prioritization Effect Under Nonmatching Conditions"
E[67] = (
    "Note. For RT, d = (Mean_Stranger \u2212 Mean_Self) / Pooled_SD, such that positive values "
    "indicate faster responses to self trials (SPE). For ACC, d = (Mean_Self \u2212 Mean_Stranger) / "
    "Pooled_SD, such that positive values indicate higher accuracy for self trials (SPE). N min is "
    "the smallest bootstrap sample size at which the 95% CI no longer includes zero, as marked by "
    "vertical dashed lines in Figure 5; \"not reached\" indicates that the CI included zero across "
    "the full range of sample sizes. For the conservative approach, N max is the sample size aligned "
    "across the shape-based and label-based analyses."
)

# ------------------------------------------------ Example 2: results
E[68] = (
    "Using the conservative approach, a robust SPE was observed for both reaction time (RT) and "
    "accuracy (ACC). For RT, the label-based operationalization yielded a moderate SPE (d = 0.252, "
    "95% CI [0.227, 0.275], N = 1,563), indicating faster responses for nonmatching trials in which "
    "the label corresponded to the Self relative to those in which the label referred to other "
    "identities. The corresponding 95% confidence interval first excluded zero at merely N = 20, "
    "indicating that the label-based RT SPE can be detected even in relatively small samples (see "
    "Figure 5A). The shape-based operationalization also revealed a significant RT SPE, although "
    "the effect was substantially smaller (d = 0.123, 95% CI [0.103, 0.144], N = 1,563); in this "
    "case the 95% confidence interval first excluded zero at N = 40 (see Figure 5A). For accuracy, "
    "both operationalizations produced relatively small but statistically significant effects. The "
    "shape-based SPE was estimated at d = 0.052, 95% CI [0.035, 0.070], N = 1,494, with the "
    "confidence interval first excluding zero at N = 170 (see Figure 5B). The label-based SPE was "
    "comparable, d = 0.049, 95% CI [0.030, 0.069], N = 1,494, with the confidence interval first "
    "excluding zero at N = 210 (see Figure 5B). Taken together, a SPE was present for both RT and "
    "ACC for nonmatching trials when the conservative approach was used. Descriptively, the "
    "label-based SPE was about twice as large as the shape-based SPE for RT (0.252 vs 0.123), "
    "whereas the two operationalizations were nearly indistinguishable for ACC (0.049 vs 0.052)."
)

E[69] = (
    "When applying the liberal approach, the label-based SPE was again evident for reaction time "
    "(RT), although the effect size was smaller than that observed under the conservative approach, "
    "d = 0.125, 95% CI [0.112, 0.138], N = 3,192. The corresponding 95% confidence interval first "
    "excluded zero at N = 40 (see Figure 5C), indicating that the label-based RT effect remained "
    "detectable with relatively modest sample sizes. In contrast, the shape-based SPE was markedly "
    "attenuated under the liberal approach: the point estimate was close to zero (d = 0.005, 95% CI "
    "[\u22120.008, 0.017], N = 3,604) and the confidence interval never excluded zero across the "
    "full range of sample sizes (see Figure 5C), suggesting that the effect was too small to be "
    "detected reliably in typical experimental samples. For accuracy, neither operationalization was "
    "reliable under the liberal approach: shape-based, d = 0.009, 95% CI [\u22120.002, 0.020], "
    "N = 3,524; label-based, d = 0.009, 95% CI [\u22120.003, 0.021], N = 3,114; neither confidence "
    "interval excluded zero at any sample size (see Figure 5D)."
)

E[70] = (
    "Collectively, the presence of a SPE on nonmatching trials depended both on the "
    "operationalization of self-relevance and on how strictly the comparison conditions were "
    "purified. When only pure self versus non-self contrasts were admitted (conservative approach), "
    "the SPE was reliably present for both RT and ACC; when all nonmatching trials were retained "
    "(liberal approach), only the label-based RT effect survived. The conservative-liberal "
    "discrepancy indicates that part of the apparent nonmatching SPE in the liberal analysis is "
    "attributable to residual self-referential information in the comparison trials, exactly as "
    "anticipated above. The RT effects were consistently larger than the ACC effects, a pattern "
    "that is consistent with previous findings in the SPE literature (Liu et al., 2025). These "
    "findings underscores the importance of both adequate statistical power and transparent "
    "operational definitions when investigating the SPE under nonmatching conditions."
)

# ------------------------------------------------ Example 3
E[73] = (
    "The third example illustrates a unique advantage of the current database: the standardized "
    "coding of methodological variations in task implementation across studies. Specifically, we "
    "examined two implementation parameters that varied across experiments: stimulus presentation "
    "duration and trial number. Stimulus duration was chosen because shorter presentation times may "
    "create time pressure for participants and alter their processing strategies (Lemaire & Brun, "
    "2016; Ratcliff et al., 2016). Despite its potential theoretical relevance, variation in "
    "stimulus duration has received little attention in the SPE literature and is often treated as "
    "a minor procedural detail. Trial number was examined because the amount of behavioral data "
    "collected from each participant may influence the reliability and stability of SPE estimates, "
    "consistent with broader concerns regarding measurement precision in cognitive tasks (Liu et "
    "al., 2025). Both implementation parameters were treated as continuous variables. For each "
    "analysis, we estimated the association between the implementation parameter and SPE magnitude "
    "(Cohen's dz, computed against the Stranger baseline) using bootstrap Spearman correlations "
    "with 10,000 resamples. We report the observed Spearman \u03C1, bootstrap 95% confidence "
    "intervals (2.5th\u201397.5th percentiles), and bootstrap p values (two-tailed; statistical "
    "significance assessed at \u03B1 = .05). Two datasets were excluded before analysis "
    "(Pan_2025_unpub and Wang_2016_JEPHPP), and datasets whose Stranger-based Cohen's dz deviated "
    "from the mean by more than three standard deviations were treated as outliers and removed."
)

E[74] = (
    "The association between stimulus presentation duration and SPE magnitude was negative. "
    "Treating duration as a continuous variable (range: 100 \u2013 3,000 ms, n = 54 datasets), "
    "bootstrap Spearman correlations revealed a significant negative relationship for both RT "
    "(\u03C1 = \u2212.311, bootstrap 95% CI [\u2212.539, \u2212.052], p boot = .018) and ACC "
    "(\u03C1 = \u2212.335, bootstrap 95% CI [\u2212.548, \u2212.095], p boot = .010; Figure 6A and "
    "6B). Both bootstrap confidence intervals lay entirely below zero, providing evidence for a "
    "reliable negative association between stimulus duration and the magnitude of "
    "self-prioritization. Shorter presentation times were associated with larger SPE effect sizes, "
    "whereas longer presentation times tended to yield smaller effects."
)

E[75] = (
    "In contrast, the maximum number of trials in a dataset was not reliably associated with SPE "
    "magnitude (Figure 6C and 6D). For reaction time (RT), the bootstrap Spearman correlation was "
    "close to zero (\u03C1 = .045, bootstrap 95% CI [\u2212.222, .302], p boot = .748); for accuracy "
    "(ACC), the point estimate was numerically positive but the confidence interval again included "
    "zero (\u03C1 = .174, bootstrap 95% CI [\u2212.098, .433], p boot = .205). To check whether these "
    "associations were driven by a small number of datasets with extreme trial counts, we conducted "
    "a sensitivity analysis excluding the three datasets with the largest trial numbers; the "
    "picture was unchanged (RT: \u03C1 = .077, p = .560; ACC: \u03C1 = .195, p = .132). The number "
    "of trials a dataset contains was therefore not a reliable moderator of the SPE in the present "
    "database."
)

E[76] = (
    "Together, these exploratory findings indicate that the magnitude of the SPE varies with how "
    "the task is implemented, but that not every candidate implementation parameter is a reliable "
    "moderator. Shorter stimulus presentation durations were associated with larger SPE magnitudes, "
    "and this held for both RT and ACC, whereas the maximum number of trials was unrelated to SPE "
    "magnitude. These findings should be interpreted with caution. The relationship between SPE "
    "magnitude and stimulus presentation duration may not be strictly linear and may depend on "
    "important boundary conditions. For example, the SPE may change when the stimulus presentation "
    "duration becomes subliminal. Likewise, the absence of a trial-number effect does not exclude "
    "non-linear or plateau-like relationships, and the available range of trial numbers is "
    "confounded with other study-level design choices. Future studies are needed to experimentally "
    "manipulate these implementation parameters to establish their causal contributions to SPE "
    "magnitude. Nevertheless, our findings highlight the importance of considering methodological "
    "details when studying self-prioritization. More broadly, they demonstrate the value of "
    "systematically coding task implementation characteristics in large-scale databases: variables "
    "that are often treated as minor procedural details may meaningfully contribute to variability "
    "in observed SPE estimates across studies, and standardized metadata are what make such "
    "questions answerable at all."
)

E[78] = ("Figure 6. Exploratory moderators of the self-prioritization effect under matching "
         "conditions.")

# ------------------------------------------------ Discussion summary
E[82] = (
    "The SPE database provides a valuable resource for understanding of SPE. Through three "
    "illustrative examples, we demonstrated how standardized, large-scale datasets can address "
    "theoretical and methodological questions that can not be solved by single small sample study. "
    "We found that the SPE was reliably positive against every baseline condition but that the "
    "baselines did not order themselves along a simple social-distance gradient; that the presence "
    "of a SPE under nonmatching conditions depended on how self-relevance was operationalized; and "
    "that the magnitude of the SPE was related to stimulus presentation duration but not to the "
    "number of trials. Together, these findings examplify the value of such a well-maintained "
    "large-scale database for the field."
)

for i, t in E.items():
    set_par(i, t)
print('paragraphs edited:', len(E))

doc.save(DST)
print('saved ->', DST)

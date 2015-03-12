package explorviz.plugin_server.rootcausedetection.algorithm;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

import explorviz.plugin_server.rootcausedetection.RanCorrConfiguration;
import explorviz.plugin_server.rootcausedetection.exception.RootCauseThreadingException;
import explorviz.plugin_server.rootcausedetection.model.RanCorrLandscape;
import explorviz.plugin_server.rootcausedetection.util.Maths;
import explorviz.plugin_server.rootcausedetection.util.RCDThreadPool;
import explorviz.shared.model.*;

/**
 * This class contains a simple algorithm to calculate RootCauseRatings. It uses
 * the data of all directly adjacent elements of the element the RootCauseRating
 * is calculated for.
 *
 * @author Christian Claus Wiechmann, Jens Michaelis
 *
 */

public class NeighbourAlgorithm extends AbstractRanCorrAlgorithm {

	// Maps used in the landscape, required for adapting the ExplorViz Landscape
	// to a RanCorr Landscape
	private Map<Integer, ArrayList<Double>> anomalyScores;
	private Map<Integer, Double> RCRs;
	private Map<Integer, ArrayList<Integer>> sources;
	private Map<Integer, ArrayList<Integer>> targets;

	private double errorState = -2.0d;

	/**
	 * Calculate RootCauseRatings in a RanCorrLandscape and uses Anomaly Scores
	 * in the ExplorViz landscape.
	 *
	 * @param lscp
	 *            specified landscape
	 */
	public void calculate(final RanCorrLandscape lscp) {
		anomalyScores = new ConcurrentHashMap<Integer, ArrayList<Double>>();
		RCRs = new ConcurrentHashMap<Integer, Double>();
		sources = new ConcurrentHashMap<Integer, ArrayList<Integer>>();
		targets = new ConcurrentHashMap<Integer, ArrayList<Integer>>();

		generateMaps(lscp);
		generateRCRs();

		// Start the final calculation with Threads
		final RCDThreadPool<Clazz> pool = new RCDThreadPool<>(this,
				RanCorrConfiguration.numberOfThreads);

		for (final Clazz clazz : lscp.getClasses()) {
			pool.addData(clazz);
		}

		try {
			pool.startThreads();
		} catch (final InterruptedException e) {
			throw new RootCauseThreadingException(
					"NeighbourRanCorrAlgorithm#calculate(...): Threading interrupted, broken output.");
		}
	}

	@Override
	public void calculate(final Clazz clazz) {
		List<Double> results = getScores(clazz.hashCode());
		if (results == null) {
			clazz.setRootCauseRating(RanCorrConfiguration.RootCauseRatingFailureState);
			return;
		}
		final double result = correlation(results);
		if (result == errorState) {
			clazz.setRootCauseRating(RanCorrConfiguration.RootCauseRatingFailureState);
			return;
		}
		clazz.setRootCauseRating(mapToPropabilityRange(result));
	}

	/**
	 * This method walks trough all operations and generates the maps required
	 * by the algorithm.
	 *
	 * @param lscp
	 */
	private void generateMaps(final RanCorrLandscape lscp) {
		if (lscp.getCommunications() != null) {
			for (Communication comm : lscp.getCommunications()) {
				Integer target = comm.getTargetClazz().hashCode();
				Integer source = comm.getSourceClazz().hashCode();

				// This part writes the hash value of the source class to the
				// targets class list
				ArrayList<Integer> sourcesList = sources.get(target);
				if (sourcesList != null) {
					sourcesList.add(source);
				} else {
					sourcesList = new ArrayList<Integer>();
					sourcesList.add(source);
				}
				sources.put(target, sourcesList);

				// This part writes the hash value of the target class to the
				// sources class list
				ArrayList<Integer> targetsList = targets.get(source);
				if (targetsList != null) {
					targetsList.add(target);
				} else {
					targetsList = new ArrayList<Integer>();
					targetsList.add(target);
				}
				targets.put(source, targetsList);
			}
		}

		if (lscp.getOperations() != null) {
			for (CommunicationClazz operation : lscp.getOperations()) {

				Integer target = operation.getTarget().hashCode();
				ArrayList<Integer> TargetList = targets.get(target);
				// Integer source = operation.getSource().hashCode();
				if (TargetList != null) {
					for (Integer targetClass : TargetList) {
						ArrayList<Double> scores = anomalyScores.get(targetClass);
						if (scores != null) {
							scores.addAll(getValuesFromAnomalyList(getAnomalyScores(operation)));
						} else {
							scores = new ArrayList<Double>();
							scores.addAll(getValuesFromAnomalyList(getAnomalyScores(operation)));
						}
						anomalyScores.put(targetClass, scores);
					}
					// //
					// // Integer target = operation.getTarget().hashCode();
					// // ArrayList<Double> scores = anomalyScores.get(target);
					// // if (scores != null) {
					// //
					// scores.addAll(getValuesFromAnomalyList(getAnomalyScores(operation)));
					// // } else {
					// // scores = new ArrayList<Double>();
					// //
					// scores.addAll(getValuesFromAnomalyList(getAnomalyScores(operation)));
					// // }
					// // anomalyScores.put(target, scores);
				}
			}
		}
	}

	/**
	 * Calculate the Root Cause Ratings of each class with unweightedPowerMeans
	 * to save time in the final correlation phase
	 */
	public void generateRCRs() {
		for (Integer key : anomalyScores.keySet()) {
			RCRs.put(key, Maths.unweightedArithmeticMean(anomalyScores.get(key)));
		}
	}

	/**
	 * The correlation function described in the paper
	 *
	 * @param results
	 *            generated by {@Link getScores}
	 * @return the calculated RCR, RootCauseRatingUnknownState if an important
	 *         value is missing
	 */
	public double correlation(final List<Double> results) {
		if (results == null) {
			return errorState;
		}
		if (results.size() != 3) {
			return errorState;
		}
		final Double ownMedian = results.get(0);
		final Double inputMedian = results.get(1);
		final Double outputMax = results.get(2);

		if ((ownMedian == null) || (inputMedian == null) || (outputMax == null)) {
			return errorState;
		}

		// If the local median can not be calculated, return error value
		if (ownMedian == errorState) {
			return errorState;
		}

		// If there are no incoming or outgoing dependencies, return ownMedian.
		// Not described in Marwede et al
		if ((inputMedian == errorState) || (outputMax == errorState)) {
			return ownMedian;
		}

		// The regular algorithm as described in Marwede et al
		if ((inputMedian > ownMedian) && (outputMax <= ownMedian)) {
			return ((ownMedian + 1) / 2.0);
		} else if ((inputMedian <= ownMedian) && (outputMax > ownMedian)) {
			return ((ownMedian - 1) / 2.0);
		} else {
			return ownMedian;
		}
	}

	/**
	 * Aggregates the scores of all Callers of the observed class as described
	 * in Marwede
	 *
	 * @param inputScores
	 *            all input RCRs available
	 * @return
	 */
	private double getMedianInputScore(final List<Double> inputScores) {
		if (inputScores.size() == 0) {
			return errorState;
		}
		return Maths.unweightedArithmeticMean(inputScores);
	}

	/**
	 * Generating the scores required for the correlation function
	 *
	 * @param clazz
	 *            The observed Class
	 * @return The required values for the correlation function, first the own
	 *         RCR, second the input score, third the output score
	 */
	private List<Double> getScores(Integer clazz) {

		final List<Double> results = new ArrayList<>();
		Double RCR = RCRs.get(clazz);
		if (RCR == null) {
			results.add(errorState);
		} else {
			results.add(RCR);
		}

		// Collect all RCR of the Callers of the observed class
		ArrayList<Integer> sourcesList = sources.get(clazz);
		ArrayList<Double> inputRCRs = new ArrayList<Double>();
		if (sourcesList != null) {
			for (Integer source : sourcesList) {
				Double inputRCR = RCRs.get(source);
				if (inputRCR != null) {
					inputRCRs.add(RCRs.get(source));
				}
			}
		}

		results.add(getMedianInputScore(inputRCRs));

		Double outputScore = errorState;
		// Run trough all Callees of the observed classes and get the maximum
		// rating
		ArrayList<Integer> targetList = targets.get(clazz);
		if (targetList != null) {
			for (Integer target : targetList) {
				Double outputRCR = RCRs.get(target);
				if (outputRCR != null) {
					outputScore = Math.max(outputRCR, outputScore);
				}
			}
		}

		results.add(outputScore);
		return results;
	}
}

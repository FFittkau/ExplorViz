package explorviz.plugin_server.rootcausedetection.model;

import java.util.HashSet;
import java.util.Set;

import explorviz.plugin_server.rootcausedetection.algorithm.*;
import explorviz.shared.model.*;
import explorviz.shared.model.System;

/**
 * This class provides methods to calculate and persist RootCauseRatings. It is
 * also used to convert ExplorViz landscapes to a format RanCorr algorithms can
 * use.
 *
 * @author Christian Claus Wiechmann
 *
 */
public class RanCorrLandscape {

	//
	// Attribute declarations
	//

	private final Set<Application> applications;
	private final Set<Component> packages;
	private final Set<Clazz> classes;
	private final Set<CommunicationClazz> operations;

	//
	// Constructors
	//

	/**
	 * Create new RanCorrLandscape.
	 */
	public RanCorrLandscape() {
		applications = new HashSet<>();
		packages = new HashSet<>();
		classes = new HashSet<>();
		operations = new HashSet<>();
	}

	/**
	 * Creates a RanCorrLandscape based on a given ExplorViz-Landscape.
	 *
	 * @param landscape
	 *            landscape to be converted
	 */
	public RanCorrLandscape(Landscape landscape) {
		applications = new HashSet<>();
		packages = new HashSet<>();
		classes = new HashSet<>();
		operations = new HashSet<>();

		for (System system : landscape.getSystems()) {
			for (NodeGroup nodeGroup : system.getNodeGroups()) {
				for (Node node : nodeGroup.getNodes()) {
					for (Application application : node.getApplications()) {
						// add all applications
						addApplication(application);

						for (CommunicationClazz operation : application.getCommunications()) {

							// add all operations in the current application
							addOperation(operation);
						}

						for (Component component : application.getComponents()) {

							// add all components and classes in the current
							// application
							addComponentsAndClasses(component);
						}
					}
				}
			}
		}
	}

	//
	// Getters/Setters
	//

	/**
	 * Add an existing ExplorViz-Application to the RanCorrLandscape as an
	 * application.
	 *
	 * @param app
	 *            specified ExplorViz-Application
	 */
	public void addApplication(final Application app) {
		applications.add(app);
	}

	/**
	 * Add an existing ExplorViz-Component to the RanCorrLandscape as a package.
	 *
	 * @param com
	 *            specified ExplorViz-Component
	 */
	public void addPackage(final Component com) {
		packages.add(com);
	}

	/**
	 * Add an existing ExplorViz-Class to the RanCorrLandscape as a class.
	 *
	 * @param cla
	 *            specified ExplorViz-Class
	 */
	public void addClass(final Clazz cla) {
		classes.add(cla);
	}

	/**
	 * Add an existing ExplorViz-CommunicationClazz to the RanCorrLandscape as
	 * an operation.
	 *
	 * @param op
	 *            specified ExplorViz-CommunicationClazz
	 */
	public void addOperation(final CommunicationClazz op) {
		operations.add(op);
	}

	//
	// Public methods
	//

	/**
	 * Calculate the RootCauseRatings of all elements in this landscape. Anomaly
	 * Scores have to be provided beforehand.
	 *
	 * @param rca
	 *            Specifies the concrete algorithm the RootCauseRatings are to
	 *            be calculated with.
	 * @param aa
	 *            Specifies the concrete algorithm for aggregation from
	 *            operation level.
	 */
	public void calculateRootCauseRatings(final AbstractRanCorrAlgorithm rca,
			final AbstractAggregationAlgorithm aa) {
		rca.calculate(this);
		aa.aggregate(this);
	}

	/**
	 * Persist all RootCauseRatings to the underlying ExplorViz landscape.
	 * {@link RanCorrLandscape#calculateRootCauseRatings
	 * calculateRootCauseRatings(final AbstractRanCorrAlgorithm, final
	 * AbstractAggregationAlgorithm)} has to be called beforehand.
	 *
	 * @param pa
	 *            Specifies the concrete algorithm the RootCauseRatings are to
	 *            be persisted with (e. g. RGB values in ExplorViz landscape).
	 */
	public void persistRootCauseRatings(final AbstractPersistAlgorithm pa) {
		pa.persist(this);
	}

	public Set<Application> getApplications() {
		return applications;
	}

	public Set<Component> getPackages() {
		return packages;
	}

	public Set<Clazz> getClasses() {
		return classes;
	}

	public Set<CommunicationClazz> getOperations() {
		return operations;
	}

	private void addComponentsAndClasses(Component component) {
		addPackage(component);

		for (Clazz clazz : component.getClazzes()) {

			// add classes of this component
			addClass(clazz);
		}

		for (Component subcomponent : component.getChildren()) {

			// add subcomponents to the RanCorr landscape
			addComponentsAndClasses(subcomponent);
		}
	}

}

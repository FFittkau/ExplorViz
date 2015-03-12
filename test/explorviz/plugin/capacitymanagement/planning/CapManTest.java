package explorviz.plugin.capacitymanagement.planning;

import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.List;

import org.junit.Before;
import org.junit.Test;

import explorviz.plugin_client.attributes.IPluginKeys;
import explorviz.shared.model.*;
import explorviz.shared.model.System;

public class CapManTest {

	private Landscape landscape;
	private double maxRootCauseRating;
	private CapManForTest capMan;
	private List<Application> applicationList;

	@Before
	public void before() {

		landscape = TestLandscapeBuilder.createStandardLandscape(0);
		maxRootCauseRating = 0.7;
		capMan = new CapManForTest();
		applicationList = new ArrayList<Application>();

		landscape.putGenericStringData(IPluginKeys.CAPMAN_NEW_PLAN_ID, "5");

		for (final System system : landscape.getSystems()) {
			for (final NodeGroup nodeGroup : system.getNodeGroups()) {
				for (final Node node : nodeGroup.getNodes()) {
					for (int i = 0; i < node.getApplications().size(); i++) {
						// manipulate RCRs
						Application currentApplication = node.getApplications().get(i);
						currentApplication.putGenericDoubleData(
								IPluginKeys.ROOTCAUSE_APPLICATION_PROBABILITY, 0.7 - (0.05 * i));
						if ((0.7 - (0.05 * i)) >= 0.6) {
							applicationList.add(currentApplication);
						}
					}
				}
			}
		}
	}

	@Test
	public void testInitializeAndGetHighestRCR() {
		assertEquals("Test, if method gets highest RCR correctly", 0.7,
				capMan.initializeAndGetHighestRCR(landscape), 0);
	}

	@Test
	public void testGetApplicationsToBeAnalyzed() {
		assertEquals("Test, if method fetches the correct applications", applicationList,
				capMan.getApplicationsToBeAnalysed(landscape, maxRootCauseRating));
	}

	/*
	 * Optional TODO: Test plan creation. It's a bit tricky, since we can only
	 * test for the side effect of the generic strings that will be the new
	 * plan.
	 */
}

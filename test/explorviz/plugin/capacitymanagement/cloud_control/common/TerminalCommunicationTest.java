package explorviz.plugin.capacitymanagement.cloud_control.common;

import static org.junit.Assert.*;

import java.util.List;

import org.junit.Assert;
import org.junit.Test;

import explorviz.plugin_server.capacitymanagement.cloud_control.common.TerminalCommunication;

public class TerminalCommunicationTest {
	@Test
	public void testSendCommand() throws Exception {
		final String text = "testing echo on console";
		final String command = "echo " + text;
		final List<String> output = TerminalCommunication.executeCommand(command);
		Assert.assertEquals("Echo should be read from console.", text, output.get(0));
	}

	@Test
	// Dieser Test funktioniert nur, mit den richtigen Zugangsdaten.
	// Außerdem ist es vermutlich nötig, novaclient installiert zu haben.
	public void testCloudAccess() throws Exception {

		final String command = "list";
		final List<String> output = TerminalCommunication.executeNovaCommand(command);
		assertNotNull(output);
		assertTrue(output.size() > 0);
		System.out.println(output);
	}

	@Test
	// Dieser Test funktioniert nur, mit den richtigen Zugangsdaten.
	// Außerdem ist es vermutlich nötig, novaclient installiert zu haben.
	public void testReplicateNode() throws Exception {

		final String command = " boot TestServer23 --flavor m1.small --image Ubuntu-13.10";
		final List<String> output = TerminalCommunication.executeCommand(command);
		assertNotNull(output);
		assertTrue(output.size() > 0);
		System.out.println(output);
	}

}
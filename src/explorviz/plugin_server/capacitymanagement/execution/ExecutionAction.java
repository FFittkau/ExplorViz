package explorviz.plugin_server.capacitymanagement.execution;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import explorviz.plugin_client.attributes.IPluginKeys;
import explorviz.plugin_client.capacitymanagement.CapManExecutionStates;
import explorviz.plugin_client.capacitymanagement.execution.SyncObject;
import explorviz.plugin_server.capacitymanagement.cloud_control.ICloudController;
import explorviz.plugin_server.capacitymanagement.loadbalancer.ScalingGroupRepository;
import explorviz.shared.model.Node;
import explorviz.shared.model.helper.GenericModelElement;

public abstract class ExecutionAction {

	// TODO: jkr/jek: bei kopierten/neuen Knoten/Applikationen sämtliche
	// Attribute des Originals setzen

	private static final Logger LOGGER = LoggerFactory.getLogger(ExecutionAction.class);

	protected ExecutionActionState state = ExecutionActionState.INITIAL;

	public ExecutionActionState getState() {
		return state;
	}

	public void execute(final ICloudController controller, final ThreadGroup group,
			final ScalingGroupRepository repository) {
		if (!checkBeforeAction(controller)) {
			state = ExecutionActionState.REJECTED;
			return;
		}
		new Thread(group, new Runnable() {
			@Override
			public void run() {
				final SyncObject sync = synchronizeOn();
				synchronized (sync) {
					while (sync.isLockedUntilExecutionActionFinished()) {
						try {
							sync.wait();
						} catch (final InterruptedException e) {

						}
					}
					sync.setLockedUntilExecutionActionFinished(true);
					beforeAction();
					boolean success = false;
					try {

						LOGGER.info("Try " + getLoggingDescription());
						for (int i = 0; (success == false)
								&& (i < ExecutionOrganizer.MAX_TRIES_FOR_CLOUD); i++) {
							success = concreteAction(controller, repository);
							Thread.sleep(100000);
						}
					} catch (final Exception e) {
						LOGGER.error("Error while " + getLoggingDescription());
						LOGGER.error(e.getMessage(), e);
						state = ExecutionActionState.ABORTED;
					} finally {
						if (success) {

							state = ExecutionActionState.SUCC_FINISHED;
							getActionObject().putGenericData(IPluginKeys.CAPMAN_EXECUTION_STATE,
									CapManExecutionStates.NONE);
							afterAction();
							LOGGER.info("Action successfully finished: " + getLoggingDescription());
						} else {
							try {
								compensate(controller, repository);
							} catch (Exception e) {
								LOGGER.error("Error while compensating " + getLoggingDescription()
										+ e.getMessage());
							}
						}
						finallyDo();
						sync.setLockedUntilExecutionActionFinished(false);
						sync.notify();
					}
				}
			}

		}).start();

	}

	protected abstract GenericModelElement getActionObject();

	protected abstract SyncObject synchronizeOn();

	protected abstract void beforeAction();

	protected abstract boolean concreteAction(ICloudController controller,
			ScalingGroupRepository repository) throws Exception;

	protected abstract void afterAction();

	protected abstract void finallyDo();

	protected abstract String getLoggingDescription();

	protected void lockingNodeForApplications(final Node parent) {
		synchronized (parent) {
			// Am I the first Application Action on this node?
			if (parent.readRunningApplications() == 0) {
				// then get lock on node
				while (parent.isLockedUntilExecutionActionFinished()) {
					try {
						parent.wait();
					} catch (final InterruptedException e) {
					}
				}
				parent.setLockedUntilExecutionActionFinished(true);
			}
			parent.incrementRunningApplications();
		}
	}

	protected void unlockingNodeForApplications(final Node parent) {
		synchronized (parent) {
			// Am I the last running ApplicationExecutionAction on this node?
			if (parent.readRunningApplications() == 1) {
				// then release lock
				parent.setLockedUntilExecutionActionFinished(false);
			}
			parent.decrementRunningApplications();
		}
	}

	protected boolean checkBeforeAction(ICloudController controller) {
		return true;
	}

	/**
	 * Creates ExecutionAction that reverses the given action. It is assumed,
	 * that this action itself has finished successfully while another action in
	 * the same plan has failed.
	 *
	 * @return Reverse {@link ExecutionAction}.
	 */
	protected abstract ExecutionAction getCompensateAction();

	/**
	 * This method will be executed if this action itself fails. It will try to
	 * return to the state before the action.
	 *
	 * @param controller
	 *            ICloudcontroller needed for access to the cloud.
	 * @param repository
	 *            Scalinggrouprepository to fetch scalinggroup for applications.
	 * @throws Exception
	 */
	protected abstract void compensate(ICloudController controller,
			ScalingGroupRepository repository) throws Exception;
}

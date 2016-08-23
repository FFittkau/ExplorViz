package explorviz.visualization.experiment.services;

import java.io.IOException;
import java.util.List;

import com.google.gwt.user.client.rpc.RemoteService;
import com.google.gwt.user.client.rpc.RemoteServiceRelativePath;

import explorviz.shared.experiment.Question;

@RemoteServiceRelativePath("jsonservice")
public interface JSONService extends RemoteService {

	public String getJSON() throws IOException;

	public void sendJSON(String json) throws IOException;

	public List<String> getExperimentFilenames();

	public String getExperimentByTitle(String name);

	public void removeExperiment(String name);

	public Question[] getQuestionsOfExp(String name);

	public String getExperimentDetails(String title);

	public void duplicateExperiment(String json) throws IOException;

	public String downloadExperimentData(String filename) throws IOException;

	public List<String> getExperimentTitles();

}

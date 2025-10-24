package com.videoai.projects.application.port.out;

import com.videoai.projects.domain.model.Project;
import com.videoai.projects.domain.model.ProjectId;
import com.videoai.projects.domain.model.UserId;
import io.smallrye.mutiny.Uni;

import java.util.List;

public interface ProjectRepository {
    Uni<Project> save(Project project);
    Uni<Project> findById(ProjectId id);
    Uni<List<Project>> findByOwner(UserId ownerId);
    Uni<Void> delete(ProjectId id);
}

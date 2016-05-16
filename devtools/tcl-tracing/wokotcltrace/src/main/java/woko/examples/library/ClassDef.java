package woko.examples.library;

import java.util.Set;

import javax.persistence.*;

import net.sf.woko.feeds.Feedable;

import org.compass.annotations.Searchable;
import org.compass.annotations.SearchableId;
import org.compass.annotations.SearchableProperty;
import org.hibernate.validator.Length;
import org.hibernate.validator.NotNull;

import static com.mongus.beans.validation.BeanValidator.validate;

/**
 * A classdef.
 */
@Searchable
@Entity
@Feedable(maxItems=50)
public class ClassDef {

	@SearchableId
	@Id @GeneratedValue(strategy=GenerationType.AUTO)
	private Long id;
	
	@SearchableProperty
	@NotNull
	@Length(min=1,max=255)
  private String name;

	@SearchableProperty
	@Length(min=5,max=200)
	private String description;
	
	@ManyToOne(fetch = FetchType.LAZY)
	private SourceFile parent;
	
	@OneToMany(cascade=CascadeType.ALL, mappedBy="parent", fetch = FetchType.LAZY)
	private Set<MethodDef> methodDefs;
	
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		validate(name);
		this.name = name;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		validate(description);
		this.description = description;
	}

	public SourceFile getParent() {
		return parent;
	}

	public void setParent(SourceFile parent) {
		this.parent = parent;
	} 	
	
	public Set<MethodDef> getMethodDefs() {
		return methodDefs;
	}

	public void setMethodDefs(Set<MethodDef> methodDefs) {
		this.methodDefs = methodDefs;
	}
	
	
	// getTitle for showing on UI
	public String getTitle() {
		return getName();
	}
	
}

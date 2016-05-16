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
 * A sourcefile with classdefs. 
 */
@Searchable
@Entity
@Feedable(maxItems=50)
public class SourceFile {

	@SearchableId
	@Id @GeneratedValue(strategy=GenerationType.AUTO)
	private Long id;
	
	@SearchableProperty
	@NotNull
	@Length(min=1,max=1023)
  private String path;

	@SearchableProperty
	@Length(min=5,max=200)
	private String description;
	
	@ManyToOne(fetch = FetchType.LAZY)
	private Directory parent;

	@OneToMany(cascade=CascadeType.ALL, mappedBy="parent", fetch = FetchType.LAZY)
	private Set<ClassDef> classDefs;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getPath() {
		return path;
	}

	public void setPath(String path) {
		validate(path);
		this.path = path;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		validate(description);
		this.description = description;
	}

	public Directory getParent() {
		return parent;
	}

	public void setParent(Directory parent) {
		this.parent = parent;
	} 	

	public Set<ClassDef> getClassDefs() {
		return classDefs;
	}

	public void setClassDefs(Set<ClassDef> classDefs) {
		this.classDefs = classDefs;
	}

	
	// getTitle for showing on UI
	public String getTitle() {
		return getPath();
	}
	
}

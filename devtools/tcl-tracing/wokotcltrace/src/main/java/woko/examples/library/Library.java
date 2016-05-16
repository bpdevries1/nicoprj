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
 * A library. Acts as a group of BaseItems.
 */
@Searchable
@Entity
@Feedable(maxItems=50)
public class Library {

	@SearchableId
	@Id @GeneratedValue(strategy=GenerationType.AUTO)
	private Long id;
	
	@SearchableProperty
	@NotNull
	@Length(min=5,max=20)
    private String title;

	@SearchableProperty
	@Length(min=5,max=200)
	private String description;
	
	@OneToMany(cascade=CascadeType.ALL, mappedBy="library", fetch = FetchType.LAZY)
	private Set<BaseItem> items;

	
	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		validate(description);
		this.description = description;
	}

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public Set<BaseItem> getItems() {
		return items;
	}

	public void setItems(Set<BaseItem> items) {
		this.items = items;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		validate(title);
		this.title = title;
	}
    
}

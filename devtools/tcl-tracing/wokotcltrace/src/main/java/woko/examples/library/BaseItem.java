package woko.examples.library;

import java.util.Date;
import java.util.Set;

import javax.persistence.*;

import org.compass.annotations.SearchableId;
import org.compass.annotations.SearchableProperty;
import org.hibernate.validator.Length;
import org.hibernate.validator.NotNull;

import static com.mongus.beans.validation.BeanValidator.validate;

/**
 * Base class for Book and Paper. 
 * Belongs to a library (many-to-one) and may have several authors (one-to-many).
 */
@Entity
public abstract class BaseItem {

	@SearchableId
	@Id @GeneratedValue(strategy=GenerationType.AUTO)
	private Long id;
	
	@SearchableProperty
	@NotNull
	@Length(min=5,max=20)
	private String name;
	
	@SearchableProperty
	@Length(min=10,max=250)
	private String description;

	@ManyToMany
	private Set<Author> authors;
	
	@ManyToOne(fetch = FetchType.LAZY)
	private Library library;
	
	@NotNull
	private Date publicationDate;

	 @SearchableProperty
    private RatingEnum rating;

    public Set<Author> getAuthors() {
		return authors;
	}

	public void setAuthors(Set<Author> authors) {
		this.authors = authors;
	}

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

	public String getName() {
		return name;
	}

	public void setName(String name) {
		validate(name);
		this.name = name;
	}

	public Library getLibrary() {
		return library;
	}

	public void setLibrary(Library library) {
		this.library = library;
	}

	public Date getPublicationDate() {
		return publicationDate;
	}

	public void setPublicationDate(Date publicationDate) {
		validate(publicationDate);
		this.publicationDate = publicationDate;
	}

    public RatingEnum getRating() {
        return rating;
    }

    public void setRating(RatingEnum rating) {
        this.rating = rating;
    }
	
}


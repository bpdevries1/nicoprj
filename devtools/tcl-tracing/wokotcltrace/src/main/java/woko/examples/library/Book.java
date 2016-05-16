package woko.examples.library;

import static com.mongus.beans.validation.BeanValidator.validate;

import javax.persistence.Entity;

import org.compass.annotations.Searchable;
import org.compass.annotations.SearchableProperty;
import org.hibernate.validator.Length;
import org.hibernate.validator.NotNull;

/**
 * A Book.
 */
@Searchable
@Entity
public class Book extends BaseItem {
	
	@NotNull
	private Integer nbPages;

	@SearchableProperty
	@NotNull
	@Length(min=5,max=20)
	private String isbn;

    private Boolean pocketFormat;

    public Integer getNbPages() {
		return nbPages;
	}

	public void setNbPages(Integer nbPages) {
		validate(nbPages);
		this.nbPages = nbPages;
	}

	public String getIsbn() {
		return isbn;
	}

	public void setIsbn(String isbn) {
		validate(isbn);
		this.isbn = isbn;
	}

    public Boolean getPocketFormat() {
        return pocketFormat;
    }

    public void setPocketFormat(Boolean pocketFormat) {
        this.pocketFormat = pocketFormat;
    }

	
}

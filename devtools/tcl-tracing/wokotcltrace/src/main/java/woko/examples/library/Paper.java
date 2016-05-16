package woko.examples.library;

import javax.persistence.Entity;

import org.compass.annotations.Searchable;
import org.compass.annotations.SearchableProperty;
import org.hibernate.validator.Length;
import org.hibernate.validator.NotNull;

import static com.mongus.beans.validation.BeanValidator.validate;

/**
 * An article from a magazine etc.
 */
@Searchable
@Entity
public class Paper extends BaseItem {
	
	@SearchableProperty
	@Length(max=5000)
	@NotNull
	private String content;

	public String getContent() {
		return content;
	}

	public void setContent(String content) {
		validate(content);
		this.content = content;
	}

}

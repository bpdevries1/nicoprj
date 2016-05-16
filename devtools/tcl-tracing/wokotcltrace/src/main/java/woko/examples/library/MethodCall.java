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
 * A method call.
 */
@Searchable
@Entity
@Feedable(maxItems=50)
public class MethodCall {

	@SearchableId
	@Id @GeneratedValue(strategy=GenerationType.AUTO)
	private Long id;
	
	@ManyToOne(fetch = FetchType.LAZY)
	private MethodDef caller;

	@ManyToOne(fetch = FetchType.LAZY)
	private MethodDef callee;

	// number of times this method is being called.
	private Integer nCalls;
	
	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public MethodDef getCaller() {
		return caller;
	}

	public void setCaller(MethodDef caller) {
		this.caller = caller;
	} 	

	public MethodDef getCallee() {
		return callee;
	}

	public void setCallee(MethodDef callee) {
		this.callee = callee;
	} 	

  public Integer getNCalls() {
		return nCalls;
	}

	public void setNCalls(Integer nCalls) {
		validate(nCalls);
		this.nCalls = nCalls;
	} 	
	
	// getTitle for showing on UI
	public String getTitle() {
		return caller.getTitle() + " => " + callee.getTitle();
	}
	
}

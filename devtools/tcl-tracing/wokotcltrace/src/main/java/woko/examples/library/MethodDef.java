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
public class MethodDef {

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
	private ClassDef parent;
	
	@SearchableProperty
  private MethodTypeEnum methodType;

	@OneToMany(cascade=CascadeType.ALL, mappedBy="caller", fetch = FetchType.LAZY)
	private Set<MethodCall> methodCalls;

	// list of inverse calls, ie. which other methods call this method?
	@OneToMany(cascade=CascadeType.ALL, mappedBy="callee", fetch = FetchType.LAZY)
	private Set<MethodCall> methodCallsInv;
	
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

	public ClassDef getParent() {
		return parent;
	}

	public void setParent(ClassDef parent) {
		this.parent = parent;
	} 	

  public MethodTypeEnum getMethodType() {
		return methodType;
  }

  public void setMethodType(MethodTypeEnum rating) {
		this.methodType = methodType;
  }
	
	public Set<MethodCall> getMethodCalls() {
		return methodCalls;
	}

	public void setMethodCalls(Set<MethodCall> methodCalls) {
		this.methodCalls = methodCalls;
	}
		
	public Set<MethodCall> getMethodCallsInv() {
		return methodCallsInv;
	}

	public void setMethodCallsInv(Set<MethodCall> methodCallsInv) {
		this.methodCallsInv = methodCallsInv;
	}
	
	// getTitle for showing on UI
	public String getTitle() {
		return parent.getName() + "." + getName();
	}
	
}

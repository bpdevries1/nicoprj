import net.sf.woko.facets.view.ViewObjectTitle;

class ViewAuthorTitle extends ViewObjectTitle {

    String getTitle() {
        return "$targetObject.firstName $targetObject.lastName";        
    }

}
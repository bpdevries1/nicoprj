package woko.examples;

import org.hibernate.Session;
import org.compass.core.*;
import woko.examples.library.Library;
import net.sf.woko.util.testing.WokoTestCase;

/**
 * A very basic Compass unit test
 */
public class MySearchTest extends WokoTestCase {

    public MySearchTest() {
        openAndCloseSession = true;
    }
    
    public void testSearch() {

        // create
    	Library l = new Library();
        l.setTitle("this is my search");
        Session s = getSession();
        s.save(l);
        s.flush();
        getPersistenceUtil().commit();
        final Long id = l.getId();
        assertNotNull("id has not been set", id);

        closeSession();
        openSessionAndTx();

        // search
        Compass compass = getCompassUtil().getCompass();
        CompassTemplate compassTemplate = new CompassTemplate(compass);
        compassTemplate.execute(new CompassCallbackWithoutResult() {
            public void doInCompassWithoutResult(CompassSession compassSession) throws CompassException {
                CompassHits hits = compassSession.find("my");
                assertEquals("we don't have exactly one hit", 1, hits.length());
                Library l2 = (Library)hits.hit(0).getData();
                assertEquals("unexpected entity ID", id, l2.getId());
                assertEquals("undexpected property value", "this is my search", l2.getTitle());
                float score = hits.score(0);
                assertTrue("score isn't positive", score > 0.01F);
            }
        });
    }


}

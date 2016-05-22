package nl.utopics.ndv.readlog;

import java.util.*;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 * specifieke klasse voor WoonTest, bedoeld om onderscheid te kunnen maken tussen de diverse
 * soorten aanroepen van (o.a.) createOvereenkomst
 */
public class WoonTest {

  /**
   * possible toplevel methodname, concat with level below.
   */
  private static final String HANDLEXML = "handleXML";

  private static HashMap logParen = null;

  static {
    vulLogParen();
  }

  /**
   * Check the name of the ServiceCallInterface with the name of the last pushed item and
   * see if the name needs to be changed.
   * Needed because we need to distinguish createOvereenkomst with/wo saving and
   * determinePOW with/wo Collectiviteit.
   *
   * @todo put business knowledge in settings file.
   */
  public static void checkSetName(Stack callstack) {
    MethodInstance miTop = (MethodInstance)callstack.elementAt(1);

    // concat handleXML with level below
    if (miTop.getNaam().equals(HANDLEXML)) {
      if (callstack.size() > 2) {
        MethodInstance miBelow = (MethodInstance)callstack.elementAt(2);
        miTop.setNaam(miTop.getNaam() + miBelow.getNaam());
      }
    }

    MethodInstance miLast = (MethodInstance)callstack.peek();

    // check of het Glas-product voorkomt, dan hoort het bij een eigenaar (ipv. huurder)
    if (miLast.getNaam().equals("determineAcceptatieGlasVerzekering")) {
      // Glas is een product dat wel bij eigenaren hoort, maar niet bij huurders.
      if (miTop.getNaam().startsWith("handleXML createOvereenkomst")) {
        miTop.setNaam(miTop.getNaam() + " eigenaar");
      }
    }

    // check of het beveiligingskorting voorkomt, dan hoort het bij een eigenaar (ipv. huurder)
    if (miLast.getNaam().equals("determineBeveiligingsKorting")) {
      // Glas is een product dat wel bij eigenaren hoort, maar niet bij huurders.
      if (miTop.getNaam().startsWith("handleXML retrieveNota")) {
        miTop.setNaam(miTop.getNaam() + " eigenaar");
      }
    }

    /** @todo bij retrieveOvereenkomst is nu geen onderscheid te maken tussen eigenaar en huurder */

    // check of een store operatie voorkomt binnen createOvereenkomst
    //iteratie 2
    if (miTop.getNaam().startsWith("handleXML createOvereenkomst")) {
      if (miLast.getNaam().equals("start: dbStore")) {
        miTop.setNaam(miTop.getNaam() + " store");
      }
    }

    //Iteratie 3
    if (miTop.getNaam().equals("handleXMLcreateOvereenkomst")) {
      if (miLast.getNaam().equals("dbStoreObjects")) {
        miTop.setNaam(miTop.getNaam() + " store");
      }
    }
/*
    // 11-10-2002: nu geen onderscheid meer tussen met en zonder collectiviteit, altijd met.
    } else if (miTop.getNaam().equals("handleXMLdeterminePremieopgaveWoon")) {
      if (miLast.getNaam().equals("retrieveCollectiviteit")) {
        miTop.setNaam("handleXMLdeterminePremieopgaveWoon Coll");
      }
*/
  }

  private static void vulLogParen() {
    logParen = new HashMap();
    logParen.put("CFindBTABusinessLogic.doeFIndBTA: enter", "CFindBTABusinessLogic.doeFIndBTA: exit");
    logParen.put("CStoreBTABusinessLogic.doeStoreBTA: enter", "CStoreBTABusinessLogic.doeStoreBTA: exit");
    logParen.put("createBetaalafspraak", "createBetaalwijze"); // ook beetje vreemde in BTA.
    logParen.put("Dispatcher : sending reply to replyqueue", "Dispatcher : finished sending reply to replyqueue");
    logParen.put("findBetaalafspraak", "createBetaalwijze"); // beetje vreemde, nog eens aanpassen in BTA.
    logParen.put("Retrieving team", "Retrieved team");
    logParen.put("start loperservice requestEigenVerwijzing in Bean", "stop service : retourneren resultaat loperservice requestEigenVerwijzing in Bean");
    logParen.put("start: dbStoreElements", "exit: dbStoreelements");
    logParen.put("Started to retrieve team", "Retrieved team");
    logParen.put("Starting to retrieve team for medewerker", "Retrieved team for medewerker");

    logParen.put("handleXML createOvereenkomst eigenaar", "handleXML createOvereenkomst");
    logParen.put("handleXML createOvereenkomst eigenaar store", "handleXML createOvereenkomst");
    logParen.put("handleXML createOvereenkomst store", "handleXML createOvereenkomst");
    logParen.put("handleXML retrieveNota eigenaar", "handleXML retrieveNota");
    logParen.put("handleXMLcreateOfferte", "handleXML");
    logParen.put("handleXMLcreatePremieopgaveWoon", "handleXML");
    logParen.put("handleXMLdeterminePremieopgaveWoon", "handleXML");
    logParen.put("handleXMLretrievePremieopgaveWoon", "handleXML");

/*
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
    logParen.put("", "");
*/
  }

  public static boolean isLogPaar(String startregel, String stopregel) {
    String stop = (String)logParen.get(startregel.trim());
    if (stop != null) {
      return (stop.equals(stopregel.trim()));
    } else {
      return false;
    }
  }

}
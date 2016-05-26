/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package org.apache.jmeter.samplers;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutput;
import java.io.ObjectOutputStream;
import java.io.Serializable;

import org.apache.jorphan.logging.LoggingManager;
import org.apache.log.Logger;

/**
 * Lars-Erik Helander provided the idea (and original implementation) for the
 * caching functionality (sampleStore).
 */

public class HoldFileSampleSender implements SampleSender, Serializable {
	private static final Logger log = LoggingManager.getLoggerForClass();

	// private List sampleStore = new ArrayList();
	private static final String tempFilenamePrefix = "HoldFile.tmp.";

	private String tempFilename = ""; // don't nullify, as we use this instance-var for synchronisation.

	private transient FileOutputStream fosTemp = null;

	private transient ObjectOutput ooTemp = null;

	private static byte[] EMPTY_ARRAY = {};
	
	public HoldFileSampleSender() {
		log.info("Using HoldFileSampleSender for this test run (null constructor)");
		log.warn("Constructor only intended for use in testing"); // $NON-NLS-1$
		// don't init stream yet, but at time of first sampleResult; temp file only needed on remote server.
		// initOutputStream();
	}

	HoldFileSampleSender(RemoteSampleListener listener) {
		log.info("Using HoldFileSampleSender for this test run (listener constructor)");
		this.listener = listener;
		// don't init stream yet, but at time of first sampleResult; temp file only needed on remote server.
		// initOutputStream();
	}
	
	private void initOutputStream() {
		fosTemp = openTempFile();
		ooTemp = openObjectOutput(fosTemp);
	}
	
	private FileOutputStream openTempFile() {
		try {
			tempFilename = tempFilenamePrefix + Math.random();
			log.info("Created tempfile: " + tempFilename);
			return new FileOutputStream(tempFilename);
		} catch (FileNotFoundException e) {
			throw new RuntimeException(
					"Tempfile not found for HoldFileSampleSender: "
							+ tempFilename);
		}
	}

	private ObjectOutput openObjectOutput(FileOutputStream fosTemp) {
		try {
			return new ObjectOutputStream(fosTemp);
		} catch (IOException e) {
			throw new RuntimeException(
					"openObjectOutput failed for HoldFileSampleSender.");
		}

	}

	private RemoteSampleListener listener;


	public void testEnded() {
		testEnded("");
	}

	public void testEnded(String host) {
		synchronized (tempFilename) {
			if ("".equals(host)) {
				log.info("Test Ended."); // should this be debug?
			} else {
				log.info("Test Ended on " + host); // should this be debug?
			}
			FileInputStream in = null;
			ObjectInputStream si = null;
			try {
				ooTemp.flush();
				fosTemp.close();
				fosTemp = null;
				ooTemp = null;

				in = new FileInputStream(tempFilename);
				si = new ObjectInputStream(in);
				while (true) {
					SampleEvent se = (SampleEvent) si.readObject();
					if (se == null) {
						break;
					} else {
						listener.sampleOccurred(se);
					}
				}
			} catch (java.io.EOFException exEof) {
				log.debug("EOF reached.");
			} catch (Throwable ex) {
				log.error("testEnded(host)", ex);
			} finally {
				try {
					in.close();
					listener.testEnded(host);
					File f = new File(tempFilename);
					f.deleteOnExit();
				} catch (Throwable ex) {
					log.error("testEnded(host, finally clause)", ex);
				}
			}
		}
	}

	public void SampleOccurred(SampleEvent e) {
		// log.debug("Sample occurred");
		// log.info("Sample occurred");
		synchronized (tempFilename) {
			if (ooTemp == null) {
				log.debug("ooTemp is null, call init");
				initOutputStream();
			}
			try {
				cleanUpSampleresult(e.getResult(), true);
				ooTemp.writeObject(e);
			} catch (IOException exc) {
				throw new RuntimeException(
						"writeObject failed for HoldFileSampleSender.");
			}
			// ooTemp.flush();
			// sampleStore.add(e);
		}
	}

	/**
	 * Samples can be big, especially the returned html, nullify before saving.
	 * @param r
	 */
	private void cleanUpSampleresult(SampleResult r, boolean root) {
		int bytes = r.getBytes();
		r.setResponseData(EMPTY_ARRAY);				
		r.setBytes(bytes); // for calculating bytes per second.
		r.setSamplerData(null);
		r.setResponseMessage(null);
		r.setResponseHeaders(null);
		r.setRequestHeaders(null);
		SampleResult[] subresults = r.getSubResults();
		r.setURL(null);
		// if (r instanceof HTTPSampleResult) {
		// 	((HTTPSampleResult)r).setQueryString(null);
		// }
		if (!root) {
			r.setSampleLabel("sub");
		}
		
		for (int i = 0; i < subresults.length; i++) {
			cleanUpSampleresult(subresults[i], false);
		}
		// log a few things
		if (log.isDebugEnabled()) {
			if (r.getParent() != null) {
				log.info("SampleResult has parent: " + r.getSampleLabel());
			}
			if (r.getSubResults().length > 0) {
				log.info("SampleResult has sub-results: " + r.getSampleLabel());
			}
		}
	}
}

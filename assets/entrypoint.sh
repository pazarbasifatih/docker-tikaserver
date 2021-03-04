#!/bin/bash

["bin/bash", "java", "-jar" ,"/tika-server-${TIKA_VERSION}.jar", "-h", "0.0.0.0", "-p", "9998", "-enableUnsecureFeatures", "-enableFileUrl", "--config", "${GENERATE_FILE}", "--cors", "i18n-48e8c.appspot.com/*"]  

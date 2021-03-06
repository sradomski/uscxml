# minimize SCXML document and run

get_filename_component(TEST_FILE_NAME ${TESTFILE} NAME)

set(ENV{USCXML_MINIMIZE_WAIT_FOR_COMPLETION} "TRUE")
set(ENV{USCXML_MINIMIZE_RETAIN_AS_COMMENTS} "TRUE")

execute_process(COMMAND ${USCXML_TRANSFORM_BIN} -tflat -i ${TESTFILE} -o ${OUTDIR}/${TEST_FILE_NAME}.flat.scxml RESULT_VARIABLE CMD_RESULT)
if(CMD_RESULT)
	message(FATAL_ERROR "Error running ${USCXML_TRANSFORM_BIN}")
endif()

execute_process(COMMAND ${USCXML_TRANSFORM_BIN} -tmin -i ${OUTDIR}/${TEST_FILE_NAME}.flat.scxml -o ${OUTDIR}/${TEST_FILE_NAME}.flat.min.scxml RESULT_VARIABLE CMD_RESULT)
if(CMD_RESULT)
	message(FATAL_ERROR "Error running ${USCXML_TRANSFORM_BIN}")
endif()

execute_process(COMMAND ${USCXML_W3C_TEST_BIN} ${OUTDIR}/${TEST_FILE_NAME}.flat.min.scxml RESULT_VARIABLE CMD_RESULT)
if(CMD_RESULT)
	message(FATAL_ERROR "Error running ${USCXML_W3C_TEST_BIN}")
endif()

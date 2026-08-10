if(NOT DEFINED SOURCE_DIR OR NOT DEFINED PATCH_FILE)
  message(FATAL_ERROR "SOURCE_DIR and PATCH_FILE are required")
endif()

find_program(GIT_EXECUTABLE git REQUIRED)

execute_process(
  COMMAND ${GIT_EXECUTABLE} -C ${SOURCE_DIR} apply --check ${PATCH_FILE}
  RESULT_VARIABLE patch_applies
  OUTPUT_QUIET
  ERROR_QUIET)
if(patch_applies EQUAL 0)
  execute_process(
    COMMAND ${GIT_EXECUTABLE} -C ${SOURCE_DIR} apply ${PATCH_FILE}
    COMMAND_ERROR_IS_FATAL ANY)
  return()
endif()

execute_process(
  COMMAND ${GIT_EXECUTABLE} -C ${SOURCE_DIR} apply --reverse --check ${PATCH_FILE}
  RESULT_VARIABLE patch_already_applied
  OUTPUT_QUIET
  ERROR_QUIET)
if(NOT patch_already_applied EQUAL 0)
  message(FATAL_ERROR "AOTriton gfx1010 patch cannot be applied to ${SOURCE_DIR}")
endif()

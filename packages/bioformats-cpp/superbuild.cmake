# bioformats-cpp superbuild

# Options to build from git (defaults to source zip if unset)
set(head OFF CACHE BOOL "Force building from current git develop branch")
set(bf-cpp-dir "" CACHE PATH "Local directory containing the Bio-Formats source code")
set(bf-cpp-git-url "" CACHE STRING "URL of Bio-Formats git repository")
set(bf-cpp-git-branch "" CACHE STRING "URL of Bio-Formats git repository")

# Current stable release.
set(RELEASE_URL "")
set(RELEASE_HASH "")

# Current development branch (defaults for head option).
set(GIT_URL "https://github.com/ome/ome-files.git")
set(GIT_BRANCH "develop")

if(NOT head)
  if(bf-cpp-git-url)
    set(GIT_URL ${bf-cpp-git-url})
  endif()
  if(bf-cpp-git-branch)
    set(GIT_BRANCH ${bf-cpp-git-branch})
  endif()
endif()

if(bf-cpp-dir)
  set(EP_SOURCE_DOWNLOAD
    DOWNLOAD_COMMAND "")
  set(EP_SOURCE_DIR "${bf-cpp-dir}")
  set(BOOST_VERSION 1.60)
  message(STATUS "Building Bio-Formats C++ from local directory (${bf-cpp-dir})")
elseif(head OR bf-cpp-git-url OR bf-cpp-git-branch)
  set(EP_SOURCE_DOWNLOAD
    GIT_REPOSITORY "${GIT_URL}"
    GIT_TAG "${GIT_BRANCH}"
    UPDATE_DISCONNECTED 1)
  set(BOOST_VERSION 1.60)
  message(STATUS "Building Bio-Formats C++ from git (URL ${GIT_URL}, branch/tag ${GIT_BRANCH})")
else()
  set(EP_SOURCE_DOWNLOAD
    URL "${RELEASE_URL}"
    URL_HASH "${RELEASE_HASH}")
  set(BOOST_VERSION 1.60)
  message(STATUS "Building Bio-Formats C++ from source release (${RELEASE_URL})")
endif()

# Set dependency list
ome_add_dependencies(bioformats-cpp
                     DEPENDENCIES ome-xml
                     THIRD_PARTY_DEPENDENCIES boost-${BOOST_VERSION} png tiff
                                              py-sphinx gtest)

unset(CONFIGURE_OPTIONS)
list(APPEND CONFIGURE_OPTIONS
     "-DBOOST_ROOT=${OME_EP_INSTALL_DIR}"
     -DBoost_NO_BOOST_CMAKE:BOOL=true
     "-DBoost_ADDITIONAL_VERSIONS=${BOOST_VERSION}"
     ${SUPERBUILD_OPTIONS})
if(TARGET gtest)
  list(APPEND CONFIGURE_OPTIONS "-DGTEST_SOURCE=${CMAKE_BINARY_DIR}/gtest-source")
endif()
string(REPLACE ";" "^^" CONFIGURE_OPTIONS "${CONFIGURE_OPTIONS}")

ExternalProject_Add(${EP_PROJECT}
  ${OME_EP_COMMON_ARGS}
  ${EP_SOURCE_DOWNLOAD}
  SOURCE_DIR ${EP_SOURCE_DIR}
  BINARY_DIR ${EP_BINARY_DIR}
  INSTALL_DIR ""
  CONFIGURE_COMMAND ${CMAKE_COMMAND}
    "-DSOURCE_DIR:PATH=${EP_SOURCE_DIR}"
    "-DBUILD_DIR:PATH=${EP_BINARY_DIR}"
    "-DCONFIGURE_OPTIONS=${CONFIGURE_OPTIONS}"
    "-DCONFIG:INTERNAL=$<CONFIG>"
    "-DEP_SCRIPT_CONFIG:FILEPATH=${EP_SCRIPT_CONFIG}"
    -P "${GENERIC_CMAKE_CONFIGURE}"
  BUILD_COMMAND ${CMAKE_COMMAND}
    "-DSOURCE_DIR:PATH=${EP_SOURCE_DIR}"
    "-DBUILD_DIR:PATH=${EP_BINARY_DIR}"
    "-DCONFIG:INTERNAL=$<CONFIG>"
    "-DEP_SCRIPT_CONFIG:FILEPATH=${EP_SCRIPT_CONFIG}"
    -P "${GENERIC_CMAKE_BUILD}"
  INSTALL_COMMAND ${CMAKE_COMMAND}
    "-DSOURCE_DIR:PATH=${EP_SOURCE_DIR}"
    "-DBUILD_DIR:PATH=${EP_BINARY_DIR}"
    "-DCONFIG:INTERNAL=$<CONFIG>"
    "-DEP_SCRIPT_CONFIG:FILEPATH=${EP_SCRIPT_CONFIG}"
    -P "${GENERIC_CMAKE_INSTALL}"
  TEST_COMMAND ${CMAKE_COMMAND}
    "-DSOURCE_DIR:PATH=${EP_SOURCE_DIR}"
    "-DBUILD_DIR:PATH=${EP_BINARY_DIR}"
    "-DCONFIG:INTERNAL=$<CONFIG>"
    "-DEP_SCRIPT_CONFIG:FILEPATH=${EP_SCRIPT_CONFIG}"
    -P "${GENERIC_CMAKE_TEST}"
  DEPENDS
    ${EP_PROJECT}-prerequisites
  )

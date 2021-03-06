cmake_minimum_required(VERSION 2.8.3)
project(plan_keeper)

## Find catkin macros and libraries
## if COMPONENTS list like find_package(catkin REQUIRED COMPONENTS xyz)
## is used, also find other catkin packages
find_package(catkin REQUIRED COMPONENTS
  roscpp
  mrs_msgs
  std_msgs
  mrs_lib
  std_srvs
  mbzirc_msgs
  brick_mapping
  actionlib_msgs
  message_generation
  cmake_modules
)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")

# include Eigen3
find_package(Eigen3 REQUIRED)
set(Eigen_INCLUDE_DIRS ${EIGEN3_INCLUDE_DIRS})
set(Eigen_LIBRARIES ${Eigen_LIBRARIES})

###############################################
## declare ros messages, services and actions ##
################################################

add_message_files(FILES
  PlanDiagnostics.msg
  PlanStateTypes.msg
  WallState.msg
  )

add_service_files(
  FILES
  BrickPlan.srv
  ChangeState.srv
  BrickResult.srv
  SetMappedPositions.srv
  )

generate_messages(DEPENDENCIES
  sensor_msgs
  std_msgs
  geometry_msgs
  std_srvs
  mrs_msgs
  mbzirc_msgs
  brick_mapping
  actionlib_msgs
  )

###################################
## catkin specific configuration ##
###################################

catkin_package(
  INCLUDE_DIRS include
  CATKIN_DEPENDS roscpp std_msgs geometry_msgs sensor_msgs std_srvs mbzirc_msgs brick_mapping actionlib_msgs
  LIBRARIES plan_keeper
  DEPENDS Eigen
  )


###########
## Build ##
###########

include_directories(
  include
  ${catkin_INCLUDE_DIRS}
  ${Eigen_INCLUDE_DIRS}
)

# just placeholder for library
add_library(plan_keeper src/empty_main.cpp)

add_dependencies(plan_keeper
  ${${PROJECT_NAME}_EXPORTED_TARGETS}
  ${catkin_EXPORTED_TARGETS}
  )

target_link_libraries(plan_keeper
  ${catkin_LIBRARIES}
  )


## Declare a C++ executable
add_executable(keeper src/plan_keeper.cpp src/dataset_loader_wall_mbzirc.cpp)

add_dependencies(keeper 
  ${${PROJECT_NAME}_EXPORTED_TARGETS}
  ${catkin_EXPORTED_TARGETS}
  )

target_link_libraries(keeper
  ${catkin_LIBRARIES}
  ${Eigen_LIBRARIES}
  )


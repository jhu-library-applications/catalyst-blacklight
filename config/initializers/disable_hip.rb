# With horizon in read only mode or HIP unavailable,
# set horizon_read_only to true, to prevent Catalyst
# from trying to contact Horizon

JHConfig.params[:disable_hip] = false


# Recommended, set a custom outage message. 
JHConfig.params[:disable_hip_message] = "Sorry, patron account features are temporarily unavailable for maintenance. Full service is expected back by late afternoon Friday, June 7th. Sorry for the inconvenience."

filtervw <- function(a){
  
  return(filter(a, ans2 == "00" & post3 == "010" |
           ans2 == '00' &post3 == '040' |
           ans2 == '00' &post3 == '042'|
           ans2 == '00' &post1 == '6'|
           ans2 == '01' |
           ans2 == '02' |
           ans2 == '03' |
           ans2 == '05' &post3 == '010'|
           ans2 == '05' &post3 == '040'|
           ans2 == '05' &post3 == '042'|
           ans2 == '05' &post1 == '5'|
           ans2 == '05' &post1 == '6'|
           ans2 == '05' &post3 == '700'|
           ans2 == '05' &post3 == '723'|
           ans2 == '05' &post3 == '728'|
           ans2 == '05' &post3 == '729'|
           ans2 == '06' &post3 == '010'|
           ans2 == '06' &post3 == '040'|
           ans2 == '06' &post3 == '042'|
           ans2 == '06' &post1 == '5'|
           ans2 == '06' &post1 == '6'|
           ans2 == '06' &post3 == '700'|
           ans2 == '06' &post3 == '723'|
           ans2 == '06' &post3 == '728'|
           ans2 == '06' &post3 == '729'|
           ans2 == '07' &post3 == '010'|
           ans2 == '07' &post3 == '040'|
           ans2 == '07' &post3 == '042'|
           ans2 == '07' &post1 == '5'|
           ans2 == '07' &post1 == '6'|
           ans2 == '07' &post3 == '700'|
           ans2 == '07' &post3 == '723'|
           ans2 == '07' &post3 == '728'|
           ans2 == '07' &post3 == '729'|
           ans2 == '08' &post3 == '010'|
           ans2 == '08' &post3 == '040'|
           ans2 == '08' &post3 == '042'|
           ans2 == '08' &post1 == '5'|
           ans2 == '08' &post1 == '6'|
           ans2 == '08' &post3 == '700'|
           ans2 == '08' &post3 == '723'|
           ans2 == '08' &post3 == '728'|
           ans2 == '08' &post3 == '729'|
           ans2 == '09' |
           ans2 == '10' |
           ans2 == '13' |
           ans1 == '1' &post3 == '500'|
           ans1 == '1' &post3 == '501'|
           ans1 == '1' &post3 == '510'|
           ans1 == '1' &post3 == '511'|
           ans1 == '1' &post3 == '6'|
           ans1 == '1' &post3 == '723'|
           ans2 == '20' |
           ans1 == '2' &post3 == '040'|
           ans1 == '2' &post3 == '500'|
           ans1 == '2' &post3 == '501'|
           ans1 == '2' &post3 == '510'|
           ans1 == '2' &post3 == '511'|
           ans1 == '2' &post3 == '617'|
           ans1 == '2' &post3 == '723'|
           ans2 == '30' |
           ans1 == '3' &post3 == '010'|
           ans1 == '3' &post3 == '040'|
           ans1 == '3' &post3 == '042'|
           ans1 == '3' &post1 == '5'|
           ans1 == '3' &post1 == '6'|
           ans1 == '3' &post3 == '700'|
           ans1 == '3' &post3 == '723'|
           ans2 == '40' |
           ans1 == '4' &post3 == '040'|
           ans1 == '4' &post3 == '500'|
           ans1 == '4' &post3 == '501'|
           ans1 == '4' &post3 == '510'|
           ans1 == '4' &post3 == '511'|
           ans1 == '4' &post3 == '617'|
           ans1 == '4' &post3 == '723'|
           ans2 == '50' |
           ans1 == '5' &post3 == '040'|
           ans1 == '5' &post3 == '500'|
           ans1 == '5' &post3 == '501'|
           ans1 == '5' &post3 == '510'|
           ans1 == '5' &post3 == '511'|
           ans1 == '5' &post1 == '6'|
           ans1 == '5' &post3 == '723'|
           ans2 == '60' |
           ans1 == '6' &post3 == '040'|
           ans1 == '6' &post3 == '042'|
           ans1 == '6' &post1 == '5'|
           ans1 == '6' &post1 == '6'|
           ans1 == '6' &post3 == '700'|
           ans1 == '6' &post3 == '723'|
           ans2 == '70' |
           ans1 == '7' &post3 == '040'|
           ans1 == '7' &post3 == '042'|
           ans1 == '7' &post1 == '5'|
           ans1 == '7' &post1 == '6'|
           ans1 == '7' &post3 == '700'|
           ans1 == '7' &post3 == '723'|
           ans2 == '80' |
           ans1 == '8' &post3 == '040'|
           ans1 == '8' &post3 == '042'|
           ans1 == '8' &post3 == '500'|
           ans1 == '8' &post3 == '501'|
           ans1 == '8' &post3 == '510'|
           ans1 == '8' &post3 == '511'|
           ans1 == '8' &post1 == '6'|
           ans1 == '8' &post3 == '700'|
           ans1 == '8' &post3 == '723'|
           ans2 == '90' |
           ans1 == '9' &post3 == '010'|
           ans1 == '9' &post3 == '040'|
           ans1 == '9' &post3 == '042'|
           ans1 == '9' &post1 == '5'|
           ans1 == '9' &post1== '6'|
           ans1 == '9' &post3 == '700'|
           ans1 == '9' &post3 == '723'|
           ans1 == '9' &post3 == '728'|
           ans1 == '9' &post3 == '729'))
}

numerize <- function(data,vars){
  data = as.data.frame(data)
  variables <- colnames(data)
  variables <- variables[! variables %in% vars]
  for(i in variables){
    data[,i]<- as.numeric(data[,i])
    data[,i][is.na(data[,i])] <- 0
  }
  return(data)
}
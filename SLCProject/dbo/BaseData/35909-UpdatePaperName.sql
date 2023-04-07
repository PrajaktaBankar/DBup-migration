/*
Customer Support 35909: SLC User Cannot Print Projects
server :2
*/


update PPS set PPS.PaperName='Letter' 
from ProjectPaperSetting PPS WITH (NOLOCK) where PPS.ProjectId in(4196,4195,4215)
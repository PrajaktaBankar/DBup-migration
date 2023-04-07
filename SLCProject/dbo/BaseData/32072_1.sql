USE SLCProject
Go

---Customer Support 32072: Customer has multiple corrupt Reference Standards (RS#) (Grimm & Parker)
---Execute On server 3

 update ps set ps.SegmentDescription ='Acoustic Insulation:  {RS#776}; preformed glass fiber, friction fit type, unfaced.  {CH#267510}'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167841128
 update ps set ps.SegmentDescription ='Sheet Steel:  Hot-dipped galvanized steel sheet, {RS#498}, with {CH#270238} coating.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167853187
 update ps set ps.SegmentDescription ='{RS#1518} - Approval Guide{CH#259880}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887682
 update ps set ps.SegmentDescription='{RS#2016} - Fire Protection Equipment Directory{CH#259882}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887684
 update ps set ps.SegmentDescription='{RS#2014} - Electrical Appliance and Utilization Equipment Directory{CH#259881}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887683
 update ps set ps.SegmentDescription='{RS#2019} - Heating, Cooling, Ventilating and Cooking Equipment Directory{CH#259884}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887686
 update ps set ps.SegmentDescription='{RS#271} - American National Standard for Plastic Lavatories{CH#259891}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887693
 update ps set ps.SegmentDescription='{RS#232} - Performance Standards for Fabricated High Pressure Decorative Countertops{CH#259889}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887691
 update ps set ps.SegmentDescription='{RS#271} - American National Standard for Plastic Lavatories{CH#259890}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887692
 update ps set ps.SegmentDescription='AIA 201 - General Conditions of the Contract for Construction{CH#259815}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167891247
 update ps set ps.SegmentDescription='{RS#2021} - Roofing Materials and Systems Directory{CH#259886}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887688
 update ps set ps.SegmentDescription='{RS#19} - Americans with Disabilities Act (ADA) Accessibility Guidelines for Transportation Vehicles{CH#259810}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167891245
 update ps set ps.SegmentDescription='{RS#1205} - Standard Specification for Corrugated Polyethylene (PE) Pipe and Fittings{CH#259887}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887689
 update ps set ps.SegmentDescription='Grout:  Non-shrink, non-metallic aggregate type, complying with {RS#617} and capable of developing a minimum compressive strength of {CH#261581} at 28 days.  {CH#261582}'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167839273
 update ps set ps.SegmentDescription='{RS#355}.1 - Inspector`s Manual For Electric Elevators{CH#259641}.'  FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167891180
 update ps set ps.SegmentDescription='{RS#2020} - Hazardous Locations Equipment Directory{CH#259885}.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887687
 update ps set ps.SegmentDescription='{RS#355}.3 - Inspector`s Manual for Escalators and Moving Walks{CH#259643}.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167891182
 update ps set ps.SegmentDescription='{RS#2510} - Fire Protection Systems Directory{CH#259883}.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167887685
 update ps set ps.SegmentDescription='{RS#355}.2 - Inspector`s Manual For Hydraulic Elevators{CH#259642}.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167891181
 update ps set ps.SegmentDescription='Extruded Aluminum:  {RS#548} and {RS#549}, {CH#283337} finish{CH#283338}.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167857787
 update ps set ps.SegmentDescription='Comply with {RS#2230} for operating panel and interior layout of car.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167837455
 update ps set ps.SegmentDescription='Rolled Steel Sections, Shapes, Rods:  {RS#451}.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167857784
 update ps set ps.SegmentDescription='Stainless Steel Sheet:  {RS#499}, Type {CH#283333}; {CH#283334} finish{CH#283335}.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167857786
 update ps set ps.SegmentDescription='Steel Sheet:  {RS#415}, Designation CS, with {CH#283331} finish.'   FROM ProjectSegment ps with(nolock) where ps.ProjectId=4729 and ps.SegmentStatusId=167857785
 UPDATE pco set pco.OptionJson='[{"OptionTypeId":5,"OptionTypeName":"ReferenceStandard","SortOrder":1,"Value":"{\\rs\\#1}","DefaultValue":null,"Id":2013,"ValueJson":null}]' 
 FROM ProjectChoiceOption pco with(nolock) WHERE pco.SegmentChoiceId=9006575 AND pco.ChoiceOptionId=19783267
 
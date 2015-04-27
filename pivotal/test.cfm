<style type="text/css" media="screen">
  .output{
    border : solid 2px #CCCCCC; padding : 4px; width : 100%; max-height : 400px; overflow : auto; margin-bottom: 50px; background: white;">
  }
  body{background: #EEE;}
</style>


<hr>
<a href="doc.cfm">See Documentation of the Pivotal Tracker CFC</a>
<hr>


<cfscript>


token = "YOUR_TOKEN_HERE";
goodproject = "A_PROJECT_ID_YOU_OWN";
badproject = "7618";
goodStory = "A_GOOD_STORY_ID_FROM_YOUR_PROJECT";
badStory = "111112";
goodFilter = "SOME_FILTER_THAT_WILL_WORK_WITH_YOUR_PROJECT";
badFilter = "label:NO_LABEL_LIKE_THIS";



pService = createObject("component","pivotalService").init(token);
</cfscript>



GET ALL PROJECTS
<div class="output">
<cfdump var="#pService.getProjects()#" />
</div>
GET ONE PROJECT
<div class="output">
  <cfdump var="#pService.getProject(goodproject)#" />  
</div>

TRY TO GET A BAD PROJECT ID
<div class="output">
<cftry>
<cfdump var="#pService.getProject(badproject)#"/>
<cfcatch type="com.dintenfass.pivotalService">
  <strong>ERROR:</strong> 
  <cfoutput>
    <pre>
   cfcatch.message: #cfcatch.message#
   cfcatch.detail: #cfcatch.detail#
   cfcatch.errorcode: #cfcatch.errorcode#
   cfcatch.type: #cfcatch.type#</pre>
  </cfoutput>
</cfcatch>
</cftry>
</div>



GET ALL STORIES FOR A GOOD PROJECT
<div class="output">
  <cfdump var="#pService.getStories(goodProject)#" />
</div>

GET ALL STORIES FOR A BAD PROJECT

<div class="output">
<cftry>
<cfdump var="#pService.getStories(badproject)#"/>
<cfcatch type="com.dintenfass.pivotalService">
  <strong>ERROR:</strong> 
  <cfoutput>
    <pre>
   cfcatch.message: #cfcatch.message#
   cfcatch.detail: #cfcatch.detail#
   cfcatch.errorcode: #cfcatch.errorcode#
   cfcatch.type: #cfcatch.type#</pre>
  </cfoutput>
</cfcatch>
</cftry>
</div>

GET A GOOD STORY
<div class="output">
  <cfdump var="#pService.getStory(goodproject,goodstory)#" />
</div>

GET A BAD STORY IN A GOOD PROJECT
<div class="output">
<cftry>
<cfdump var="#pService.getStory(goodproject,badstory)#" />
<cfcatch type="com.dintenfass.pivotalService">
  <strong>ERROR:</strong> 
  <cfoutput>
    <pre>
   cfcatch.message: #cfcatch.message#
   cfcatch.detail: #cfcatch.detail#
   cfcatch.errorcode: #cfcatch.errorcode#
   cfcatch.type: #cfcatch.type#</pre>
  </cfoutput>
</cfcatch>
</cftry>
</div>



GET A BAD STORY IN A BAD PROJECT
<div class="output">
<cftry>
<cfdump var="#pService.getStory(badproject,badstory)#" />
<cfcatch type="com.dintenfass.pivotalService">
  <strong>ERROR:</strong> 
  <cfoutput>
    <pre>
   cfcatch.message: #cfcatch.message#
   cfcatch.detail: #cfcatch.detail#
   cfcatch.errorcode: #cfcatch.errorcode#
   cfcatch.type: #cfcatch.type#</pre>
  </cfoutput>
</cfcatch>
</cftry>
</div>


GET A FILTERED SET OF STORIES (<cfoutput>#goodfilter#</cfoutput>)
<div class="output">
  <cfdump var="#pService.getStories(goodproject,goodfilter)#" />  
</div>

USE A FILTER THAT WON'T WORK (<cfoutput>#badfilter#</cfoutput>)
<div class="output">
  <cfdump var="#pService.getStories(goodproject,badfilter)#" />  
</div>

GET ALL LABELS FOR A PROJECT
<div class="output">
  <cfdump var="#pService.getLabels(goodproject)#" />
</div>  

GET LABELS FOR A PROJECT WITH THE FILTER APPLIED (<cfoutput>#goodfilter#</cfoutput>)
<div class="output">
  <cfdump var="#pService.getLabels(goodproject, goodfilter)#" />
</div>

GET ALL RELEASES FOR A PROJECT
<div class="output">
  <cfdump var="#pService.getReleases(goodproject)#" />
</div>



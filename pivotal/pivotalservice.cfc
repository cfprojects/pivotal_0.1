<!---  
  
  
*****************************************  
TODO: 
 * Consider refactor to return a query rather than struct of structs (and/or allow user to choose)
 * getPeople
 * getReleases should have a way to get only future (and past?) releases
 * getNextRelease (and storiesForNextRelease?)
 * getStoriesByOwner
 * getPointCommitmentsByPerson (all, for a release, with a date filter)
 * getCurrentPointCommitments
 * Deal with datetime formatting - seems lame to leave them as-is if they aren't valid CF date objects
 * Decide if all story structs should have the exact same keys (ie: should there be an empty "owned_by")
 * Should labels in stories stay a string list, or be some other data type?
 * Caching - could just get all stories/projects at init, with some kind of timeout - for frequent use that would be MUCH more efficient
 * Purposefully left out most type validation for speed -- should it go back in?
 * Should stories in getAllStories, etc. be returned as an array in priority order rather than as a id-keyed struct?


********************************************  
--->


<cfcomponent hint="A basic interface to the Pivotal Tracker API" output="false">
  <cffunction name="init" access="public" output="false">
    <cfargument name="token" type="string" required="true" hint="Your API Token" />
    <cfargument name="useSSL" type="boolean" required="false" default="false" hint="Boolean for whether we should use SSL in our requests" />
    <cfargument name="version" type="string" required="false" default="v2" hint="The full string depicting the version of the API to use (by default, 'v2')" />
    <cfscript>
      var sslSlug = "";
      variables.instance = structNew();
      instance.token = arguments.token;
      if(arguments.useSSL) sslSlug = "s";
      instance.serviceURL = "http" & sslSlug & "://www.pivotaltracker.com/services/" & arguments.version & "/";
      return this;
    </cfscript>
  </cffunction>
  
  <cffunction name="getProjects" access="public" output="false" hint="Returns a struct of project structs, keyed by ID (all projects associated with the authenticated token)">
    <cfscript>
      var raw = sendRequest("projects");
      var ii = 0;
      var projects = structNew();
      var thisProjectNode = "";
      for(ii = 1; ii LTE arrayLen(raw.projects.project); ii = ii + 1){
        thisProjectNode = raw.projects.project[ii];
        projects[thisProjectNode.id.xmlText] = makeProjectFromNode(thisProjectNode);
      }
      return projects;
    </cfscript>
  </cffunction>
  
  <cffunction name="getProject" access="public" output="false" hint="Given a project ID, get a struct of the information about that project">
    <cfargument name="id" type="numeric" required="true" />
    <cfscript>
      var raw = sendRequest("projects/" & arguments.id);
      return makeProjectFromNode(raw.project);
    </cfscript>
  </cffunction>
  
  <cffunction name="getStories" access="public" output="false" hint="Given a Project ID, get all the stories for that Project in a struct of structs, keyed by story ID.  Optionally, pass a filter and/or pagination options to limit the result.">
    <cfargument name="projectID" type="numeric" required="true"/>
    <cfargument name="filter" type="string" required="false" default="" hint="Optional search string, formatted exactly as it would be inside of Pivotal" />
    <cfscript>
      var raw = "";
      var ii = 0;
      var stories = structNew();
      var thisStoryNode = "";
      var urlArgs = "projects/" & arguments.projectID & "/stories?";
      if(len(trim(arguments.filter)))
        urlArgs = urlArgs & "&filter=" & urlEncodedFormat(arguments.filter);
      raw = sendRequest(urlArgs);
      //if there are no stories, just return the empty struct
      if(NOT structKeyExists(raw.stories,"story"))
        return stories;
      //loop through all stories, building each into a struct and add the original priority index to each  
      for(ii = 1; ii LTE arrayLen(raw.stories.story); ii = ii + 1){
        thisStoryNode = raw.stories.story[ii];
        stories[thisStoryNode.id.xmlText] = makeStoryFromNode(thisStoryNode);
        stories[thisStoryNode.id.xmlText].priorityindex = ii;
      }
      return stories;      
    </cfscript>
  </cffunction>
  
  <cffunction name="getStory" access="public" output="false" hint="Get a given story as a struct, given a projectID and a storyID">
    <cfargument name="projectID" type="numeric" required="true" />
    <cfargument name="storyID" type="numeric" required="true" />
    <cfscript>
      var raw = sendRequest("projects/" & arguments.projectID & "/stories/" & arguments.storyID);
      return makeStoryFromNode(raw.story);
    </cfscript>
  </cffunction>
  
  <cffunction name="getLabels" returntype="struct" access="public" output="false" hint="Get all Labels given a Project ID as a struct, with all IDs of stories with that label in a struct, with the value being the priorityIndex for each story.  Optionally pass a filter in the form of a Pivotal search string.">
    <cfargument name="projectID" type="numeric" required="true"  />
    <cfargument name="filter" type="string" required="false" default="" hint="Optional search string, formatted exactly as it would be inside of Pivotal" />
    <cfscript>
    //Worth noting that until we do caching, this is a relatively very expensive thing to do
    //But, it's valuable enough for some purposes that I'm putting it in
      var labels = structNew();
      var ii = 0;
      var theseLabels = "";
      var sid = "";
      var thisStory = "";
      var thisLabel = "";
      var stories = getStories(arguments.projectID, arguments.filter);
      //loop through all stories, for each, if it has labels, loop through those, adding them to the struct
      for(sid in stories){
        thisStory = stories[sid];
        if(structKeyExists(thisStory,"labels")){
          //could probably optimize this for the case of a single label, but probably low ROI
          theseLabels = listToArray(thisStory.labels);
          for(ii = 1; ii LTE arrayLen(theseLabels); ii = ii + 1){
            thisLabel = theseLabels[ii];
            if(NOT structKeyExists(labels,thisLabel))
              labels[thisLabel] = structNew();
            labels[thisLabel][thisStory.id] = thisStory.priorityIndex;
          }
        }
      }
      return labels;
    </cfscript>
  </cffunction>
  <cffunction name="getReleases" access="public" output="false" hint="Get just the Release type 'stories'">
    <cfargument name="projectID" type="numeric" required="true"  />
    <cfscript>
      var filter = "type:Release";
      return getStories(arguments.projectID,filter);
    </cfscript>
  </cffunction>
  
    <!---  
    *********************************
    ***** PRIVATE METHODS BELOW *****
    *********************************
    --->
  
  <cffunction name="makeProjectFromNode" access="private" output="false" hint="Takes a project XML node and make a struct of project info">
    <cfargument name="node" required="true" />
    <cfscript>
      return nodeToStruct(node);
    </cfscript>
  </cffunction>
  
  <cffunction name="makeStoryFromNode" access="private" output="false" hint="Takes an XML 'story' node and returns a CF struct">
    <cfargument name="node" required="true"  />
    <cfscript>
      var story = nodeToStruct(node);
      //if there is an iteration associated with this story, build out that information in a sub-struct
      if(structKeyExists(story,"iteration"))
        story.iteration = nodeToStruct(node.iteration);
      return story;      
    </cfscript>
  </cffunction>
  
  <cffunction name="sendRequest" access="private" output="false">
    <cfargument name="URLArgs" type="string" required="true" hint="The full set of arguments, as a string, to put in the URL request" />
    <cfargument name="method" type="string" required="false" default="GET"/>
    <cfscript>
      var cfhttp = "";
      var errorMessage = "";
      var badIDs = "";
    </cfscript>
    <cftry>
      <cfhttp url="#getServiceURL()##arguments.URLArgs#" method="#arguments.method#" throwonerror="true" timeout="120">
        <cfhttpparam type="header" name="X-TrackerToken" value="#getAPIToken()#"/>
        <cfhttpparam type="header" name="Content-type" value="application/xml"/>
      </cfhttp>
      <cfcatch type="COM.Allaire.ColdFusion.HTTPNotFound">
        <cfscript>
          //get the IDs parsed from the string used as the arguments
          badIDs = getIDsFromArgs(arguments.URLArgs);
          //if we have a bad story ID, show the right error
          if(badIDs.storyID){
            throw("404","Bad Project ID and/or Story ID", "The Project ID " & badIDs.projectID & " and/or the Story ID " & badIds.storyID & " do not appear to be valid for your Pivotal Tracker API Token.","404");
          }
          //if we have a bad project ID, show that error
          if(badIds.projectID){
            throw("404","Bad Project ID", "The Project ID " & badIDs.projectID & " does not appear to be valid for your Pivotal Tracker API Token.","404",arguments.URLArgs);
          }
          //we shouldn't ever get here, but if we do that's some unknown error
          throw("404","Bad Request", "An unknown error occurred attempting the HTTP request to the Pivotal Tracker API - the service returned a 404 error.","404");
        </cfscript>
      </cfcatch>
    </cftry>
    <cfreturn xmlParse(cfhttp.fileContent)>
  </cffunction>
  <!---  This is a helper that just takes the node names as keys and xmlText as values to build a struct  --->
  <cffunction name="nodeToStruct" access="private" output="false">
    <cfargument name="node" required="true" />
    <cfscript>
      var ii = 0; 
      var obj = structNew();
      var thisNode = "";
      for(ii = 1; ii LTE arrayLen(node.xmlChildren); ii = ii + 1){
        thisNode = node.xmlChildren[ii];
        obj[thisNode.xmlName] = thisNode.xmlText;
      }
      return obj;
    </cfscript>
  </cffunction>

  <cffunction name="getServiceURL" access="private" output="false">
    <cfreturn instance.serviceURL>
  </cffunction>
  <cffunction name="getAPIToken" access="private" output="false">
    <cfreturn instance.token>
  </cffunction>
  <cffunction name="getIDsFromArgs" returntype="struct" access="private" output="false" hint="An internal worker function to grab storyID and projectID from the arguments passed in the REST URL.  Sets both to 0 if not found.">
    <cfargument name="URLArgs" required="true" />
    <cfscript>
      //check to see if we have a projectID, a storyID, or both - use that information to determine a good error message
      var ids = structNew();
      var idPosLen = REFind("projects/([[:digit:]]+)(/stories/([[:digit:]]+))*.*",arguments.URLArgs,1,true);
      ids.storyID = 0;
      ids.projectID = 0;
      //if we have any match, it means there is at least one ID
      if(idPosLen.pos[1]){
        //if there is len to the 4th match, that's the story ID  
        if(idPosLen.len[4])
          ids.storyID = mid(arguments.URLArgs,idPosLen.pos[4],idPosLen.len[4]);
        //if there is len to the 2nd match, that's a project ID
        if(idPosLen.len[2])
          ids.projectID = mid(arguments.URLArgs,idPosLen.pos[2],idPosLen.len[2]); 
      }
      return ids;
    </cfscript>
  </cffunction>
  <cffunction name="throw" access="private" output="false">
    <cfargument name="subType" required="true" />
    <cfargument name="message" type="string" required="true" />
    <cfargument name="detail" type="string" required="false" default=""  />
    <cfargument name="errorcode" type="string" required="false" default="" />
    <cfargument name="extendedinfo" type="string" required="false" default="" />
    <cfthrow type="com.dintenfass.pivotalService.#arguments.subType#" message="#arguments.message#" detail="#arguments.detail#" errorcode="#arguments.errorcode#" extendedinfo="#arguments.extendedinfo#"/>
  </cffunction>  
</cfcomponent>

class ProvenanceEvent
    def self.provenance_event_values(project: , event_type:)
        values = {
          event_type: ["Submssion" , "Status Update"], # submission or status update
          event_details: project.metadata[:data_sponsor], # requested by datasponsor + timestamp
          event_person: current_user.uid, #netid of the event creator
          event_timestamp: DateTime.nowstrftime("yyyy-MM-dd'T'HH:mm"), #timestamp on event creation  
        }
    
    
    def create(project:)
        provenance_values = provenance_event_values(project)
        provenance_values.event_type = "Submission"

    def update(project:)
        provenance_values = provenance_event_values(project)
        provenance_values.event_type = "Status Update"

    def initialize(project: , current_user:)
        @project = project
        @current_user = current_user


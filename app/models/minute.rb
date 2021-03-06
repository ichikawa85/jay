class Minute < ActiveRecord::Base
  belongs_to :author, :class_name => "User", :foreign_key => :author_id
  has_and_belongs_to_many :tags
  before_validation :add_unique_action_item_marker

  def organization
    ApplicationSettings.github.organization
  end

  # Replace action-item number into corresponding GitHub issue number.
  # Example:
  #   "-->(name !:0001)" becomes "-->(name nomlab/jay/#10)"
  def cooked_content
    self.read_attribute(:content).split("\n").map do |line|
      line.gsub(/-->\((.+?)!:([0-9]{4})\)/) do |macth|
        assignee, action = $1.strip, $2

        issue = ActionItem.find_by_id(action.to_i).try(:github_issue)

        issue ? "-->(#{assignee} #{issue}{:data-action-item=\"#{action}\"})" :
          "-->(#{assignee} !:#{action})"
      end
    end.join("\n")
  end

  # Add action-item number with prefix "!:".
  # Example:
  #   "-->(name)" becomes "-->(name !:0001)"
  def add_unique_action_item_marker
    self.content = self.content.split("\n").map do |line|
      line.gsub(/-->\((.+?)(?:!:([0-9]{4}))?\)/) do |macth|
        assignee, action = $1.strip, $2

        action = ActionItem.create.uid unless action
        "-->(#{assignee} !:#{action})"
      end
    end.join("\n")
  end
end

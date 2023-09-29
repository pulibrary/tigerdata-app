# frozen_string_literal: true
class Role < ApplicationRecord
  # rubocop:disable Rails/HasAndBelongsToMany
  #  Leave the generated code back as the rubocop reccomended code does not allow for deletes
  #  Following [PDC Describe](https://github.com/pulibrary/pdc_describe/blob/main/app/models/role.rb#L4C5-L7C5)
  has_and_belongs_to_many :users, join_table: :users_roles
  # rubocop:enable Rails/HasAndBelongsToMany

  belongs_to :resource,
             polymorphic: true,
             optional: true

  validates :resource_type,
            inclusion: { in: Rolify.resource_types },
            allow_nil: true

  scopify
end

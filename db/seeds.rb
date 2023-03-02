# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

YAML.load_file("seeds/roles.yaml").each do |role|
    Role.create(
        name: role["name"],
        description_md: role["description_md"]
    )
end

YAML.load_file("seeds/users.yaml").each do |user|
    u = User.create(
        provider: "cas",
        uid: user["uid"],
        email: user["uid"] + "@princeton.edu"
    )
    user["allowed_roles"].each do |allowed_role|
        r = Role.find_by(name: allowed_role)
        u.allowed_roles.build(role: r)
    end
end

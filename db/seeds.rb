# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

YAML.load_file("seeds/roles.yaml").each do |seed_role|
    Role.create!(
        name: seed_role["name"],
        description_md: seed_role["description_md"]
    )
end

YAML.load_file("seeds/users.yaml").each do |seed_user|
    uid = seed_user["uid"]
    u = User.create!(
        provider: "cas",
        uid: uid,
        email: uid + "@princeton.edu"
    )
    seed_user["allowed_roles"].each do |allowed_role|
        r = Role.find_by(name: allowed_role)
        u.allowed_roles.create!(role: r)

        p = Project.create!(data: {name: "Sample project with #{uid} as #{allowed_role}"})
        p.project_user_roles.create!(role: r, user: u)
    end
end

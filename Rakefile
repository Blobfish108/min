require "rake/clean"

GENERATED_PARSER = "lib/min/generated_parser.rb"
CLOBBER.include GENERATED_PARSER

file GENERATED_PARSER => "lib/parser.y" do |t|
  if ENV['DEBUG']
    sh "racc -g -v -o #{t.name} #{t.prerequisites.first}"
  else
    sh "racc -o #{t.name} #{t.prerequisites.first}"
  end
end

task :parser => GENERATED_PARSER
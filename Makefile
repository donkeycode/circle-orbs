pack:
	circleci orb pack ${project}/src/ > ${project}.yaml
	
publish-dev:
	make pack project=${project}
	circleci orb publish ${project}.yaml donkeycode/${project}@dev:first

publish:
	make publish-dev project=${project}
	circleci orb publish promote donkeycode/${project}@dev:first patch

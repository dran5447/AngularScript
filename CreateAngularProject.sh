#!/bin/bash
# To run, call ./CreateAngularProject.sh in bash in the directory where you want to create your Angular app
# Should already be executable (chmod +x CreateAngularProject.sh)
# Requires NPM to already be installed

cd $(dirname $0)
cat asciiArt.txt

red=${txtbld}$(tput setaf 1) #  red
cyan=${txtbld}$(tput setaf 6) #  cyan
NC="${txtbld}$(tput sgr0)" # Reset

echo -e -n "${cyan}Enter name for the new Angular app : ${NC}"
read appname
if [ "$appname" == "" ]; then
	while [ "$appname" == "" ]; do 
		echo "${red}App name cannot be blank. ${red}"
		echo -e -n "${cyan}Please enter name for the new Angular app, or 'q' to quit :${NC} "
		read appname
		if [ "$appname" == "q" ]; then
			exit 1
		fi
	done
fi

# from https://gitlab.com/snippets/3883
isNpmPackageInstalled() {
  npm list --depth 1 -g $1 > /dev/null 2>&1
}

echo "${cyan}Checking for Angular NPM package...${NC}"
if isNpmPackageInstalled @angular/cli
then
	echo "${NC}Angular is installed."
else
	echo "${cyan}Package not installed. Installing Angular...${NC}"
	npm install -g @angular/cli
fi

echo "${cyan}Creating '$appname'...${NC}"
ng new $appname  # TODO need validation against names beginning w. numbers
# NOTE on windows may need user to add %AppData%\npm to PATH if ng command isnt found - https://github.com/angular/angular-cli/issues/1183
cd $appname

boolAddRoutes=x
while [ "$boolAddRoutes" != "n" -a "$boolAddRoutes" != "y" ]; do    # Protect against excessive 'enters' while ng creates app
	echo -e -n "${cyan}Would you like to quick-add routes? y/n :${NC} "
	read boolAddRoutes
done

if [ "$boolAddRoutes" == "y" ]; then
	# Create routing file
	# Generate AppRoutingModule app-routing.module.ts in the src/app folder
	# --flat puts the file in src/app instead of its own folder.
	#--module=app tells the CLI to register it in the imports array of the AppModule.
	ng generate module app-routing --flat --module=app

	# TODO there's probably a better way to batch these
	cd ./src/app
	sed -i "\:</h1>: a\ <nav>\n\</nav>" app.component.html
	sed -i "\:</nav>: a\ <router-outlet></router-outlet>" app.component.html
	sed -i "\:@NgModule({: i\ const routes: Routes = [\n\  { path: '', redirectTo: '/', pathMatch: 'full' },\n];" app-routing.module.ts
	sed -i "\:import { CommonModule } from '@angular/common';: a\ import { RouterModule, Routes } from '@angular/router';" app-routing.module.ts
	sed -i "\:imports: a\ RouterModule.forRoot(routes),"  app-routing.module.ts
	sed -i "\:@NgModule({: a\ exports: [ RouterModule ]," app-routing.module.ts
	cd ../..

	# Add quickstart for routing and components
	choice="a"
	while [ "$choice" == "a" ]; 
	do
		# Collect route name input
		echo -e -n "${cyan}Enter route path to add (in the form of 'route/subroute') :${NC} "
		read route
		echo -e -n "${cyan}Enter the page name for the path (for now only single word,starting with a capital letter): ${NC}"
		read pagename
		lowercasepagename=${pagename,,}

		# TODO error check that the route and page don't have the same name (even if cased); angular will complain
		# TODO error check - generated page name itself should be camel case, the folder will have dashes

		# Confirm route prior to adding
		echo -e -n "${cyan}Adding route '/$route' and page '$pagename'. Confirm? y/n : ${NC}"
		read confirminput

		if [ "$confirminput" == "y" ]; then
			# Generate component
			# The CLI generates the folder & files for the DashboardComponent and declares it in AppModule.
			ng generate component $pagename
			
			cd ./src/app

			# Update app-routing.module to add import and path to new component
			sed -i "\:import { CommonModule } from '@angular/common';: a\ import { "$pagename"Component } from './"$lowercasepagename"/"$lowercasepagename".component';" app-routing.module.ts

			# Add route to list
			sed -i "\:Routes = \[: a\ { path: '"$route"', component: "$pagename"Component }," app-routing.module.ts

			# Update app.component.html nav to add link to new component
			sed -i "\:<nav>: a\ <a routerLink='/"$route"'>"$pagename"</a>" app.component.html

			cd ../..

			echo "Added route"
		else
			# TODO should probably allow a quick-edit if feeling generous
			echo "${cyan}Abandoned adding route.${NC}"
		fi

		# loop
		echo -e -n "${cyan}Hit 'a' to add another, or any other key to exit :${NC} "
		read choice
	done
fi

echo "${cyan}Your new Angular app $appname has been created"
echo "${cyan}cd to the project and use 'ng serve -o' to run the app and open in browser${NC}"
exit


# TODO react flow script
#npx create-react-app $appname
#cd $appname
# TODO do updates
#TODO add comments to use npm start
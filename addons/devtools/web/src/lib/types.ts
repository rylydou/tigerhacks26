export type Command = {
	id: string;
	name: string;
	description?: string;
	args?: CommandArgument[];
};


export type CommandArgument = {
	name: string;
	type: string;
};

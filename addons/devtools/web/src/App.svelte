<script lang="ts">
	import ky from 'ky'
	import { onMount } from 'svelte'
	import type { Command } from './lib/types'
	import { dummyCommands } from './lib/data'

	let commands = $state<Command[]>([])

	const normalizeText = (text: string) => text.toLocaleLowerCase().replaceAll(/[^\w]/g, '')

	let filteredCommands = $derived(
		commands.filter((command) => {
			if (!searchQuery) return true

			const query = normalizeText(searchQuery)

			if (normalizeText(command.name).includes(query)) return true
			if (command.description && normalizeText(command.description).includes(query)) return true
			return false
		}),
	)

	let searchQuery = $state('')
	let errorText = $state('')

	onMount(() => {
		fetchCommands()
	})

	const fetchCommands = async () => {
		commands = dummyCommands
		return

		const res = await ky('/commands').json()

		if (!res) {
			return
		}

		commands = res as Command[]
	}

	const executeCommand = async (command: Command) => {
		ky.post('execute', { body: command.id })
	}
</script>

<main>
	<h1>{commands.length} commands</h1>

	<div class="toolbar">
		<div class="search-box">
			<input type="search" placeholder="Filter commands..." bind:value={searchQuery} />
		</div>
		<button class="btn" type="button">Refresh</button>
	</div>

	<div class="command-list">
		{#each filteredCommands as command}
			<button
				class="command"
				onclick={() => {
					executeCommand(command)
				}}
			>
				<div class="command__header">
					<!-- <button class="btn command__run-button" type="button">Run</button> -->
					<h3 class="command__title">{command.name}</h3>
				</div>
				<p class="command__description">
					{command.description}
				</p>
			</button>
		{/each}
	</div>
</main>


def topological_sort(graph: dict):
    '''
    Generic topological sorting algorithm

    graph:
        Dictionary where each key represents a graph node,
        and each value is a list of connected nodes.

        The graph has to be acyclic. If a cycle is detected,
        a ValueError is raised.

        Ex. {'A': ['B', 'C'], 'B': [], 'C': ['B']}

    returns:
        List of nodes in topological order
    '''
    status = {node: '' for node in graph}
    result = []

    def visit(node):
        if status[node] == 'temp': raise ValueError("Not a DAG!")
        if status[node] == 'done': return
        status[node] = 'temp'
        for neighbor in graph[node]:
            visit(neighbor)
        status[node] = 'done'
        result.insert(0, node)

    for node in graph:
        if status[node]: continue
        visit(node)

    return result


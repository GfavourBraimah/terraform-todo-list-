import React, { useState } from 'react';

function App() {
  const [tasks, setTasks] = useState([
    { id: 1, text: 'Rotate AWS access keys', completed: false },
    { id: 2, text: 'Check backup status', completed: false },
    { id: 3, text: 'Review cloudwatch alarms', completed: false }
  ]);
  const [newTask, setNewTask] = useState('');

  const addTask = () => {
    if (newTask.trim() !== '') {
      setTasks([...tasks, { id: Date.now(), text: newTask, completed: false }]);
      setNewTask('');
    }
  };

  const toggleTask = (id) => {
    setTasks(tasks.map(task => 
      task.id === id ? { ...task, completed: !task.completed } : task
    ));
  };

  const deleteTask = (id) => {
    setTasks(tasks.filter(task => task.id !== id));
  };

  return (
    <div style={{ padding: '20px', maxWidth: '600px', margin: '0 auto' }}>
      <h1>DevOps To-Do List</h1>
      <div>
        <input
          type="text"
          value={newTask}
          onChange={(e) => setNewTask(e.target.value)}
          placeholder="Add a new task..."
          style={{ padding: '8px', width: '70%' }}
        />
        <button onClick={addTask} style={{ padding: '8px 15px', marginLeft: '10px' }}>
          Add Task
        </button>
      </div>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {tasks.map(task => (
          <li key={task.id} style={{ margin: '10px 0', display: 'flex', alignItems: 'center' }}>
            <input
              type="checkbox"
              checked={task.completed}
              onChange={() => toggleTask(task.id)}
              style={{ marginRight: '10px' }}
            />
            <span style={{ textDecoration: task.completed ? 'line-through' : 'none', flex: 1 }}>
              {task.text}
            </span>
            <button 
              onClick={() => deleteTask(task.id)}
              style={{ background: 'red', color: 'white', border: 'none', padding: '5px 10px' }}
            >
              Delete
            </button>
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
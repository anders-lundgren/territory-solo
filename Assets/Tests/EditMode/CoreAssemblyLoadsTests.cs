using NUnit.Framework;

namespace Game.Core.Tests
{
    public class CoreAssemblyLoadsTests
    {
        [Test]
        public void CoreAssemblyLoads()
        {
            _ = new GameState();
            Assert.Pass();
        }
    }
}